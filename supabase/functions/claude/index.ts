// Parley's one backend endpoint: POST /functions/v1/claude.
// Order of checks: body size, signed-in Supabase user, valid body, rate limits, then the Claude
// call. The Anthropic key exists only as a Supabase secret; the app never sees it.
import { createClient } from "jsr:@supabase/supabase-js@2.118.0";
import { agentTurn, extractJobPost, publicError, streamReply, type Usage } from "./claude.ts";
import { LIMITS } from "./config.ts";
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

    // Stop the Claude call (and its billing) the moment the app goes away.
    const abort = new AbortController();
    request.signal.addEventListener("abort", () => abort.abort());

    if (req.mode === "chat" || req.mode === "vision") return streamResponse(req, abort, logId);
    const result = req.mode === "extract"
      ? await extractJobPost(req, abort.signal)
      : await agentTurn(req, abort.signal);
    await logUsage(logId, result.usage);
    return json(result);
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
    body = await request.json();
  } catch {
    throw new HttpError(400, "Body must be JSON.");
  }
  const checked = validateRequest(body);
  if (!checked.ok) throw new HttpError(400, checked.error);
  return checked.value;
}

// The network the request came from, hashed so no raw IP address is ever stored.
async function ipHash(request: Request): Promise<string | null> {
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  if (!ip) return null;
  const salted = new TextEncoder().encode(`${Deno.env.get("SUPABASE_URL")}|${ip}`);
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", salted));
  return Array.from(digest.slice(0, 16), (b) => b.toString(16).padStart(2, "0")).join("");
}

// Checks every limit and records the request in one locked database step, so a burst of
// parallel requests cannot slip past a count. Fails closed: no slot, no Claude call.
async function claimSlot(userId: string, ip: string | null, req: ClaudeRequest): Promise<number> {
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

function streamResponse(req: ClaudeRequest, abort: AbortController, logId: number): Response {
  const encoder = new TextEncoder();
  const body = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (event: unknown) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(event)}\n\n`));
      try {
        for await (const event of streamReply(req, abort.signal)) {
          if (event.type === "done") await logUsage(logId, event.usage);
          send(event);
        }
      } catch (error) {
        if (abort.signal.aborted) return; // The app left; the stream is already closed.
        console.error("claude stream failed", error);
        send({ type: "error", message: publicError(error).message });
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

async function logUsage(logId: number, usage: Usage) {
  const { error } = await admin
    .from("claude_requests")
    .update({ input_tokens: usage.input_tokens, output_tokens: usage.output_tokens })
    .eq("id", logId);
  if (error) console.error("usage update failed", error.message);
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
