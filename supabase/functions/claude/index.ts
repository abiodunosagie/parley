// Parley's one backend endpoint: POST /functions/v1/claude.
// Order of checks: body size, signed-in Supabase user, valid body, rate limits, the search and
// document budgets, then the Claude call. Whatever the call spends is logged at the end, even
// when the app disconnects. The Anthropic key exists only as a Supabase secret; the app never
// sees it.
import { createClient } from "jsr:@supabase/supabase-js@2.118.0";
import { agentTurn, countInputTokens, Meter, publicError, streamReply, structured } from "./claude.ts";
import { LIMITS, MAX_TOKENS, STREAMING_MODES } from "./config.ts";
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

  try {
    if (!Deno.env.get("ANTHROPIC_API_KEY")) throw new HttpError(503, "The server is not set up yet.");
    const size = Number(request.headers.get("Content-Length") ?? "0");
    if (size > LIMITS.maxBodyBytes) throw new HttpError(413, "That request is too large.");

    const userId = await signedInUser(request);
    const req = await readBody(request);
    const logId = await claimSlot(userId, await ipHash(request), req);
    if (req.options.webSearch) await checkSearchBudget(userId);

    // Stop the Claude call (and its billing) the moment the app goes away.
    const abort = new AbortController();
    request.signal.addEventListener("abort", () => abort.abort());

    if (req.mode === "document") {
      const tokens = await countInputTokens(req, abort.signal);
      if (tokens > LIMITS.maxDocumentInputTokens) {
        throw new HttpError(413, "That document is too long for Parley. Try a shorter PDF, about 25 pages.");
      }
    }

    const meter = new Meter();
    if ((STREAMING_MODES as readonly string[]).includes(req.mode)) return streamResponse(req, abort, logId, meter);
    try {
      const result = req.mode === "extract"
        ? await structured(req, JOB_POST_SCHEMA, abort.signal, meter)
        : req.mode === "receipt"
        ? await structured(req, RECEIPT_SCHEMA, abort.signal, meter)
        : await agentTurn(req, abort.signal, meter);
      return json(result);
    } finally {
      await logUsage(logId, meter, req);
    }
  } catch (error) {
    if (error instanceof HttpError) return json({ error: error.message }, error.status);
    console.error("claude request failed", error);
    const { message, status } = publicError(error);
    return json({ error: message }, status);
  }
});

async function signedInUser(request: Request): Promise<string> {
  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) throw new HttpError(401, "Sign in first.");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, "Your session ended. Sign in again.");
  return data.user.id;
}

async function readBody(request: Request): Promise<ClaudeRequest> {
  let body: unknown;
  try {
    body = JSON.parse(await readLimited(request, LIMITS.maxBodyBytes));
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(400, "Body must be JSON.");
  }
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
async function claimSlot(userId: string, ip: string, req: ClaudeRequest): Promise<number> {
  const { data, error } = await admin.rpc("claim_claude_request", {
    p_user: userId,
    p_ip_hash: ip,
    p_mode: req.mode,
    p_model: req.model,
    p_user_per_minute: LIMITS.perUserPerMinute,
    p_user_per_day: LIMITS.perUserPerDay,
    p_ip_per_day: LIMITS.perIpPerDay,
    p_project_per_day: LIMITS.projectPerDay,
    p_user_tokens_per_day: LIMITS.userTokensPerDay,
    p_project_tokens_per_day: LIMITS.projectTokensPerDay,
  });
  if (error) {
    console.error("rate limit check failed", error.message);
    throw new HttpError(503, "Parley is busy. Try again in a moment.");
  }
  const row = (data as { request_id: number | null; refusal: string | null }[] | null)?.[0];
  if (!row?.request_id) throw new HttpError(429, REFUSALS[row?.refusal ?? ""] ?? REFUSALS.project_day);
  return row.request_id;
}

function streamResponse(req: ClaudeRequest, abort: AbortController, logId: number, meter: Meter): Response {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (event: unknown) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(event)}\n\n`));
      try {
        for await (const event of streamReply(req, abort.signal, meter)) send(event);
      } catch (error) {
        if (abort.signal.aborted) return; // The app left; the stream is already closed.
        console.error("claude stream failed", error);
        send({ type: "error", message: publicError(error).message });
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
