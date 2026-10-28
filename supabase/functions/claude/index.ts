// Parley's one backend endpoint: POST /functions/v1/claude.
// Order of checks: body size, signed-in Supabase user, valid body, rate limits, the search and
// document budgets, then the Claude call. Whatever the call spends is logged at the end, even
// when the app disconnects. The project's Anthropic key exists only as a Supabase secret; the app
// never sees it. A user who adds their own key under Account sends it with each request: it is used
// for that request only, never stored and never logged, and the shared daily budgets do not
// apply to it because the user pays for it.
import { createClient } from "jsr:@supabase/supabase-js@2.118.0";
import Anthropic from "npm:@anthropic-ai/sdk@1.1.0";
import { agentTurn, clientFor, countInputTokens, Meter, publicError, streamReply, structured } from "./claude.ts";
import { LIMITS, MAX_TOKENS, OWN_KEY_PATTERN, STREAMING_MODES } from "./config.ts";
import { JOB_POST_SCHEMA, RECEIPT_SCHEMA } from "./schemas.ts";
import { type ClaudeRequest, validateRequest } from "./validate.ts";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

// The mobile app needs no CORS. These headers stay so a web build (Expo web, Flutter web) of the
// same app can call the function; auth is a Bearer header, never a cookie, so * is safe.
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const REFUSALS: Record<string, string> = {
  user_minute: "Slow down a little. Try again in a minute.",
  user_day: "You reached today's limit. Come back tomorrow.",
  user_tokens: "You reached today's limit. Come back tomorrow.",
  ip_day: "This network reached today's limit. Try again tomorrow.",
  project_day: "Parley reached its daily limit. Try again tomorrow.",
};

const TEXT_DECODER = new TextDecoder();

class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response(null, { headers: CORS });
  if (request.method !== "POST") return json({ error: "Use POST." }, 405);

  let ownKey: string | null = null;
  try {
    const size = Number(request.headers.get("Content-Length") ?? "0");
    if (size > LIMITS.maxBodyBytes) throw new HttpError(413, "That request is too large.");

    const userId = await signedInUser(request);
    const body = await readJson(request);
    ownKey = readOwnKey(body);
    if (!ownKey && !Deno.env.get("ANTHROPIC_API_KEY")) throw new HttpError(503, "The server is not set up yet.");
    const req = validated(body);
    const logId = await claimSlot(userId, await ipHash(request), req, ownKey !== null);
    if (req.options.webSearch && !ownKey) await checkSearchBudget(userId);
    const anthropic = clientFor(ownKey);

    // Stop the Claude call (and its billing) the moment the app goes away.
    const abort = new AbortController();
    request.signal.addEventListener("abort", () => abort.abort());

    // The document cap protects the shared budget; on the user's own key the API's own limits apply.
    if (req.mode === "document" && !ownKey) {
      const tokens = await countInputTokens(anthropic, req, abort.signal);
      if (tokens > LIMITS.maxDocumentInputTokens) {
        throw new HttpError(413, "That document is too long for Parley. Try a shorter PDF, about 25 pages.");
      }
    }

    const meter = new Meter();
    if ((STREAMING_MODES as readonly string[]).includes(req.mode)) return streamResponse(anthropic, req, abort, logId, meter, ownKey);
    try {
      const result = req.mode === "extract"
        ? await structured(anthropic, req, JOB_POST_SCHEMA, abort.signal, meter)
        : req.mode === "receipt"
        ? await structured(anthropic, req, RECEIPT_SCHEMA, abort.signal, meter)
        : await agentTurn(anthropic, req, abort.signal, meter);
      return json(result);
    } finally {
      await logUsage(logId, meter, req);
    }
  } catch (error) {
    if (error instanceof HttpError) return json({ error: error.message }, error.status);
    logFailure("claude request failed", error, ownKey);
    const { message, status } = publicError(error, ownKey !== null);
    return json({ error: message }, status);
  }
});

// The user's own key from the body, or null when the request uses the project's key. A key that is
// present but not shaped like an Anthropic key is refused rather than ignored, so a typo never
// quietly spends the shared budget. validateRequest never copies api_key into the request it
// builds, so the key cannot reach Claude or the logs by that path.
function readOwnKey(body: unknown): string | null {
  const value = (body as { api_key?: unknown } | null)?.api_key;
  if (value === undefined || value === null) return null;
  if (typeof value !== "string" || !OWN_KEY_PATTERN.test(value)) {
    throw new HttpError(400, "That API key does not look like a Claude key. Check it under Account.");
  }
  return value;
}

// Logs a failure with no trace of the user's key: only the error's kind, status and message, with
// the key blanked out in case an upstream message ever echoes it.
function logFailure(label: string, error: unknown, ownKey: string | null) {
  const status = error instanceof Anthropic.APIError ? ` ${error.status}` : "";
  const name = error instanceof Error ? error.name : "Error";
  let message = error instanceof Error ? error.message : String(error);
  if (ownKey) message = message.replaceAll(ownKey, "[key]");
  console.error(`${label}: ${name}${status} ${message}${ownKey ? " (own key)" : ""}`);
}

async function signedInUser(request: Request): Promise<string> {
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) throw new HttpError(401, "Sign in first.");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "Your session ended. Sign in again.");
  return data.user.id;
}

async function readJson(request: Request): Promise<unknown> {
  try {
    return JSON.parse(await readLimited(request, LIMITS.maxBodyBytes));
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(400, "Body must be JSON.");
  }
}

function validated(body: unknown): ClaudeRequest {
  const checked = validateRequest(body);
  if (!checked.ok) throw new HttpError(400, checked.error);
  return checked.value;
}

// Reads the body while counting bytes, so a request without (or lying about) Content-Length
// still cannot be larger than the limit.
async function readLimited(request: Request, max: number): Promise<string> {
  if (!request.body) return "";
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > max) {
      await reader.cancel();
      throw new HttpError(413, "That request is too large.");
    }
    chunks.push(value);
  }
  const all = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    all.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return TEXT_DECODER.decode(all);
}

// Searches are billed apart from tokens, so each user has a daily number of them.
async function checkSearchBudget(userId: string) {
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { data, error } = await admin
    .from("claude_requests")
    .select("web_searches")
    .eq("user_id", userId)
    .eq("own_key", false)
    .gt("web_searches", 0)
    .gt("created_at", since);
  if (error) {
    console.error("search budget check failed", error.message);
    throw new HttpError(503, "Parley is busy. Try again in a moment.");
  }
  const used = (data ?? []).reduce((sum, row) => sum + (row.web_searches as number), 0);
  if (used >= LIMITS.webSearchesPerUserPerDay) {
    throw new HttpError(429, "You reached today's web search limit. Turn web search off or come back tomorrow.");
  }
}

// The network the request came from, hashed so no raw IP address is ever stored. Supabase's edge
// sits behind Cloudflare, which sets CF-Connecting-IP itself and rejects requests that try to
// send their own (checked live), so it cannot be faked the way X-Forwarded-For can. Without it
// the request shares one "unknown" bucket, so a missing header limits harder instead of not at all.
async function ipHash(request: Request): Promise<string> {
  const ip = request.headers.get("cf-connecting-ip")?.trim();
  if (!ip) console.warn("request without CF-Connecting-IP; using the shared unknown bucket");
  const salted = new TextEncoder().encode(`${Deno.env.get("SUPABASE_URL")}|${ip || "unknown"}`);
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", salted));
  return Array.from(digest.slice(0, 16), (b) => b.toString(16).padStart(2, "0")).join("");
}

// Checks every limit and records the request in one locked database step, so a burst of
// parallel requests cannot slip past a count. Fails closed: no slot, no Claude call.
// On the user's own key only the per-minute limit and a generous daily count of own-key requests
// apply, and the row is marked so it never counts against the shared daily budgets.
async function claimSlot(userId: string, ip: string, req: ClaudeRequest, ownKey: boolean): Promise<number> {
  const { data, error } = await admin.rpc("claim_claude_request", {
    p_user: userId,
    p_ip_hash: ip,
    p_mode: req.mode,
    p_model: req.model,
    p_user_per_minute: LIMITS.perUserPerMinute,
    p_user_per_day: ownKey ? LIMITS.ownKeyPerUserPerDay : LIMITS.perUserPerDay,
    p_ip_per_day: LIMITS.perIpPerDay,
    p_project_per_day: LIMITS.projectPerDay,
    p_user_tokens_per_day: LIMITS.userTokensPerDay,
    p_project_tokens_per_day: LIMITS.projectTokensPerDay,
    p_own_key: ownKey,
  });
  if (error) {
    console.error("rate limit check failed", error.message);
    throw new HttpError(503, "Parley is busy. Try again in a moment.");
  }
  const row = (data as { request_id: number | null; refusal: string | null }[] | null)?.[0];
  if (!row?.request_id) throw new HttpError(429, REFUSALS[row?.refusal ?? ""] ?? REFUSALS.project_day);
  return row.request_id;
}

function streamResponse(
  anthropic: Anthropic,
  req: ClaudeRequest,
  abort: AbortController,
  logId: number,
  meter: Meter,
  ownKey: string | null,
): Response {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (event: unknown) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(event)}\n\n`));
      try {
        for await (const event of streamReply(anthropic, req, abort.signal, meter)) send(event);
      } catch (error) {
        if (abort.signal.aborted) return; // The app left; the stream is already closed.
        logFailure("claude stream failed", error, ownKey);
        send({ type: "error", message: publicError(error, ownKey !== null).message });
      } finally {
        await logUsage(logId, meter, req);
      }
      controller.close();
    },
    cancel() {
      abort.abort();
    },
  });
  return new Response(body, {
    headers: { ...CORS, "Content-Type": "text/event-stream", "Cache-Control": "no-cache" },
  });
}

// Logs what the request spent. When the API never reported a figure (the call failed or the app
// left early) a cautious estimate stands in, so aborting a request never makes it free.
async function logUsage(logId: number, meter: Meter, req: ClaudeRequest) {
  const { error } = await admin
    .from("claude_requests")
    .update({
      input_tokens: meter.input ?? estimateInputTokens(req),
      output_tokens: meter.input === null ? MAX_TOKENS[req.mode] : meter.output,
      web_searches: meter.searches,
    })
    .eq("id", logId);
  if (error) console.error("usage update failed", error.message);
}

// About four characters per token for text, and Claude's documented ~1,600 tokens for a phone
// photo at 1568 px. PDFs: ~1,000 tokens per 10 KB of file, on the high side.
function estimateInputTokens(req: ClaudeRequest): number {
  let tokens = 0;
  for (const message of req.messages) {
    if (typeof message.content === "string") {
      tokens += message.content.length / 4;
      continue;
    }
    for (const block of message.content ?? []) {
      if (block.type === "image") tokens += 1600;
      else if (block.type === "document" && block.source.type === "base64") tokens += (block.source.data.length * 0.75) / 10;
      else tokens += JSON.stringify(block).length / 4;
    }
  }
  return Math.ceil(tokens);
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
