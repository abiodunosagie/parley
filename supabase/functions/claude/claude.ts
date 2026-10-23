// The only file that talks to the Anthropic API. Chat and vision stream text back as it is
// written; extraction and the agent return one finished response.
import Anthropic from "npm:@anthropic-ai/sdk@1.1.0";
import { EFFORT, MAX_TOKENS, MODELS, SERVER_FALLBACK_BETA } from "./config.ts";
import { SYSTEM_PROMPTS } from "./prompts.ts";
import { AGENT_TOOLS, JOB_POST_SCHEMA } from "./schemas.ts";
import type { ClaudeRequest } from "./validate.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

export type Usage = { input_tokens: number; output_tokens: number };

const usageOf = (message: Anthropic.Beta.BetaMessage): Usage => ({
  input_tokens: message.usage.input_tokens,
  output_tokens: message.usage.output_tokens,
});

// Opus and Sonnet can decline a request through safety classifiers. With server-side fallbacks
// the API re-runs a declined request on Anthropic's recommended model inside the same call.
// Haiku has no server-side fallback, so its refusals reach the app as stop_reason "refusal".
function baseParams(req: ClaudeRequest) {
  return {
    model: req.model,
    max_tokens: MAX_TOKENS[req.mode],
    system: SYSTEM_PROMPTS[req.mode],
    messages: req.messages,
    ...(MODELS[req.model].serverFallback ? { betas: [SERVER_FALLBACK_BETA], fallbacks: "default" as const } : {}),
  };
}

// Server-sent events the app reads line by line: {"type":"text"}, then one {"type":"done"}.
export type StreamEvent =
  | { type: "text"; text: string }
  | { type: "done"; stop_reason: string | null; usage: Usage };

export async function* streamReply(req: ClaudeRequest, signal: AbortSignal): AsyncGenerator<StreamEvent> {
  const stream = anthropic.beta.messages.stream(
    { ...baseParams(req), output_config: { effort: EFFORT[req.mode] } },
    { signal },
  );
  for await (const event of stream) {
    if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
      yield { type: "text", text: event.delta.text };
    }
  }
  const final = await stream.finalMessage();
  yield { type: "done", stop_reason: final.stop_reason, usage: usageOf(final) };
}

export type ExtractResult = { fields: Record<string, unknown> | null; stop_reason: string | null; usage: Usage };

export async function extractJobPost(req: ClaudeRequest, signal: AbortSignal): Promise<ExtractResult> {
  const response = await anthropic.beta.messages.create(
    {
      ...baseParams(req),
      output_config: { effort: EFFORT[req.mode], format: { type: "json_schema", schema: JOB_POST_SCHEMA } },
    },
    { signal },
  );
  const usage = usageOf(response);
  if (response.stop_reason !== "end_turn") return { fields: null, stop_reason: response.stop_reason, usage };
  const text = response.content.find((b) => b.type === "text");
  return { fields: text?.type === "text" ? JSON.parse(text.text) : null, stop_reason: response.stop_reason, usage };
}

export type AgentResult = {
  // Claude's whole turn, thinking blocks included. The app appends it to the conversation
  // unchanged, runs any tool_use blocks, and sends the results back as the next user turn.
  content: Anthropic.Beta.BetaContentBlock[];
  stop_reason: string | null;
  usage: Usage;
};

export async function agentTurn(req: ClaudeRequest, signal: AbortSignal): Promise<AgentResult> {
  const response = await anthropic.beta.messages.create(
    { ...baseParams(req), tools: AGENT_TOOLS, output_config: { effort: EFFORT[req.mode] } },
    { signal },
  );
  return { content: response.content, stop_reason: response.stop_reason, usage: usageOf(response) };
}

// The app shows these words as they are, so they never carry internal details.
export function publicError(error: unknown): { message: string; status: number } {
  if (error instanceof Anthropic.RateLimitError) return { message: "Claude is busy right now. Try again in a moment.", status: 503 };
  if (error instanceof Anthropic.BadRequestError) return { message: "Claude could not take that request.", status: 400 };
  if (error instanceof Anthropic.AuthenticationError) return { message: "The server is not set up yet.", status: 503 };
  if (error instanceof Anthropic.APIConnectionError) return { message: "Could not reach Claude. Try again.", status: 502 };
  return { message: "Something went wrong. Try again.", status: 502 };
}
