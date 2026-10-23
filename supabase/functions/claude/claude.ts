// The only file that talks to the Anthropic API. Chat, photos, documents and rewriting stream back
// as they are written; extraction, receipts and the agent return one finished response.
import Anthropic from "npm:@anthropic-ai/sdk@1.1.0";
import { EFFORT, MAX_TOKENS, type Mode, MODELS, SERVER_FALLBACK_BETA, SHOW_THINKING, WEB_SEARCH_MAX_USES } from "./config.ts";
import { SYSTEM_PROMPTS, WEB_SEARCH_PROMPT } from "./prompts.ts";
import { AGENT_TOOLS } from "./schemas.ts";
import { ALLOWED_BLOCKS, type ClaudeRequest } from "./validate.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

type ContentBlock = Anthropic.Beta.BetaContentBlock;
export type Usage = { input_tokens: number; output_tokens: number };

const usageOf = (message: Anthropic.Beta.BetaMessage): Usage => ({
  input_tokens: message.usage.input_tokens,
  output_tokens: message.usage.output_tokens,
});

const addUsage = (a: Usage, b: Usage): Usage => ({
  input_tokens: a.input_tokens + b.input_tokens,
  output_tokens: a.output_tokens + b.output_tokens,
});

// A long search turn can pause; it resumes by sending the paused reply back. Capped so one
// request cannot loop.
const MAX_RESUMES = 2;

// Web search stays declared once a conversation has searched, because earlier search blocks are
// only valid next to the tool that produced them.
const usesWebSearch = (req: ClaudeRequest) =>
  req.mode === "chat" && (req.options.webSearch || req.messages.some((m) =>
    m.role === "assistant" && Array.isArray(m.content) && m.content.some((b) => b.type === "server_tool_use")
  ));

// Opus and Sonnet can decline a request through safety classifiers. With server-side fallbacks
// the API re-runs a declined request on Anthropic's recommended model inside the same call.
// Haiku has no server-side fallback, so its refusals reach the app as stop_reason "refusal".
function baseParams(req: ClaudeRequest) {
  const search = usesWebSearch(req);
  return {
    model: req.model,
    max_tokens: MAX_TOKENS[req.mode],
    system: SYSTEM_PROMPTS[req.mode] + (search ? WEB_SEARCH_PROMPT : ""),
    messages: req.messages,
    // Summarized reasoning is free to read: billing is the same as when it is hidden.
    ...(SHOW_THINKING.includes(req.mode) ? { thinking: { type: "adaptive" as const, display: "summarized" as const } } : {}),
    ...(search ? { tools: [{ type: "web_search_20250305" as const, name: "web_search" as const, max_uses: WEB_SEARCH_MAX_USES }] } : {}),
    ...(MODELS[req.model].serverFallback ? { betas: [SERVER_FALLBACK_BETA], fallbacks: "default" as const } : {}),
  };
}

// Claude's turn as the app stores it for the next request: only the block types this mode
// accepts back, so a stored conversation always passes validation when it continues.
function replayable(mode: Mode, content: ContentBlock[]): ContentBlock[] {
  return content.filter((b) => ALLOWED_BLOCKS[mode].assistant.includes(b.type));
}

/** A source Claude cited, shaped for the app: a web page, or pages of the PDF. */
export type Source =
  | { kind: "web"; url: string; title: string; cited_text: string }
  | { kind: "page"; title: string; cited_text: string; start_page: number; end_page: number };

// Server-sent events the app reads line by line. The last one is "done", carrying Claude's whole
// turn (thinking and search results included) so the app can send it back on the next turn.
export type StreamEvent =
  | { type: "thinking"; text: string }
  | { type: "text"; text: string }
  | { type: "search"; query: string }
  | { type: "source"; source: Source }
  | { type: "done"; stop_reason: string | null; usage: Usage; content: ContentBlock[] };

function sourceOf(citation: Anthropic.Beta.BetaTextCitation): Source | null {
  switch (citation.type) {
    case "web_search_result_location":
      return { kind: "web", url: citation.url, title: citation.title ?? citation.url, cited_text: citation.cited_text };
    case "page_location":
      return {
        kind: "page",
        title: citation.document_title ?? "Document",
        cited_text: citation.cited_text,
        start_page: citation.start_page_number,
        // end_page_number is exclusive in the API; the app shows the last page included.
        end_page: Math.max(citation.start_page_number, citation.end_page_number - 1),
      };
    default:
      return null;
  }
}

export async function* streamReply(req: ClaudeRequest, signal: AbortSignal): AsyncGenerator<StreamEvent> {
  let messages = req.messages;
  let usage: Usage = { input_tokens: 0, output_tokens: 0 };
  const content: ContentBlock[] = [];
  let wroteText = false;

  for (let round = 0; ; round++) {
    const stream = anthropic.beta.messages.stream(
      { ...baseParams({ ...req, messages }), output_config: { effort: EFFORT[req.mode] } },
      { signal },
    );
    const searchInput = new Map<number, string>();
    let lastType = "";
    for await (const event of stream) {
      if (event.type === "content_block_start") {
        const type = event.content_block.type;
        // Text after a search starts a new paragraph; text split by citations runs on.
        if (type === "text" && wroteText && lastType !== "text") yield { type: "text", text: "\n\n" };
        if (type === "server_tool_use") searchInput.set(event.index, "");
        lastType = type;
      } else if (event.type === "content_block_delta") {
        const delta = event.delta;
        if (delta.type === "text_delta") {
          wroteText = true;
          yield { type: "text", text: delta.text };
        } else if (delta.type === "thinking_delta") {
          yield { type: "thinking", text: delta.thinking };
        } else if (delta.type === "citations_delta") {
          const source = sourceOf(delta.citation);
          if (source) yield { type: "source", source };
        } else if (delta.type === "input_json_delta" && searchInput.has(event.index)) {
          searchInput.set(event.index, searchInput.get(event.index)! + delta.partial_json);
        }
      } else if (event.type === "content_block_stop" && searchInput.has(event.index)) {
        const query = queryOf(searchInput.get(event.index)!);
        if (query) yield { type: "search", query };
      }
    }
    const final = await stream.finalMessage();
    usage = addUsage(usage, usageOf(final));
    content.push(...final.content);
    if (final.stop_reason !== "pause_turn" || round >= MAX_RESUMES) {
      yield { type: "done", stop_reason: final.stop_reason, usage, content: replayable(req.mode, content) };
      return;
    }
    // Resume: send the paused turn back unchanged and let the API continue it.
    messages = [...req.messages, { role: "assistant", content: content as Anthropic.Beta.BetaContentBlockParam[] }];
  }
}

function queryOf(json: string): string | null {
  try {
    const input = JSON.parse(json);
    return typeof input?.query === "string" ? input.query : null;
  } catch {
    return null;
  }
}

export type StructuredResult = { fields: Record<string, unknown> | null; stop_reason: string | null; usage: Usage };

/** One JSON answer in exactly [schema]'s shape. Used by extraction and receipts. */
export async function structured(req: ClaudeRequest, schema: Record<string, unknown>, signal: AbortSignal): Promise<StructuredResult> {
  const response = await anthropic.beta.messages.create(
    { ...baseParams(req), output_config: { effort: EFFORT[req.mode], format: { type: "json_schema", schema } } },
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
  content: ContentBlock[];
  stop_reason: string | null;
  usage: Usage;
};

export async function agentTurn(req: ClaudeRequest, signal: AbortSignal): Promise<AgentResult> {
  const response = await anthropic.beta.messages.create(
    { ...baseParams(req), tools: AGENT_TOOLS, output_config: { effort: EFFORT[req.mode] } },
    { signal },
  );
  return { content: replayable(req.mode, response.content), stop_reason: response.stop_reason, usage: usageOf(response) };
}

// The app shows these words as they are, so they never carry internal details.
export function publicError(error: unknown): { message: string; status: number } {
  if (error instanceof Anthropic.RateLimitError) return { message: "Claude is busy right now. Try again in a moment.", status: 503 };
  if (error instanceof Anthropic.BadRequestError) return { message: "Claude could not take that request.", status: 400 };
  if (error instanceof Anthropic.AuthenticationError) return { message: "The server is not set up yet.", status: 503 };
  if (error instanceof Anthropic.APIConnectionError) return { message: "Could not reach Claude. Try again.", status: 502 };
  return { message: "Something went wrong. Try again.", status: 502 };
}
