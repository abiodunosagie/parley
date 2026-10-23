// Checks every request body before anything reaches Claude. The app is open source, so the
// server treats every field as untrusted: allowed models only, allowed block types per mode, hard
// size caps, and every block rebuilt from known fields so nothing extra rides along to the API.
// Pure functions, covered by validate_test.ts.
import type Anthropic from "npm:@anthropic-ai/sdk@1.1.0";
import { LIMITS, MODELS, MODES, type Mode, type ModelId } from "./config.ts";

type Message = Anthropic.Beta.BetaMessageParam;
type Block = Anthropic.Beta.BetaContentBlockParam;

export type ClaudeRequest = { mode: Mode; model: ModelId; messages: Message[] };
export type Validation = { ok: true; value: ClaudeRequest } | { ok: false; error: string };

const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"] as const;
type ImageType = (typeof IMAGE_TYPES)[number];

// Which content block types each mode may carry, per role. Agent turns echo Claude's own blocks
// back, thinking included, so that mode accepts them on the assistant side.
const ALLOWED_BLOCKS: Record<Mode, { user: string[]; assistant: string[] }> = {
  chat: { user: ["text"], assistant: ["text"] },
  vision: { user: ["text", "image"], assistant: ["text"] },
  extract: { user: ["text"], assistant: ["text"] },
  agent: { user: ["text", "tool_result"], assistant: ["text", "tool_use", "thinking", "redacted_thinking"] },
};

class Invalid extends Error {}

const isObject = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

const isMode = (v: unknown): v is Mode => typeof v === "string" && (MODES as readonly string[]).includes(v);
const isModel = (v: unknown): v is ModelId => typeof v === "string" && Object.hasOwn(MODELS, v);

export function validateRequest(body: unknown): Validation {
  try {
    return { ok: true, value: parse(body) };
  } catch (e) {
    if (e instanceof Invalid) return { ok: false, error: e.message };
    throw e;
  }
}

function parse(body: unknown): ClaudeRequest {
  if (!isObject(body)) throw new Invalid("Body must be a JSON object.");
  const { mode, model, messages } = body;
  if (!isMode(mode)) throw new Invalid("Unknown mode.");
  if (!isModel(model)) throw new Invalid("Unknown model.");
  if (!Array.isArray(messages) || messages.length === 0) throw new Invalid("Messages are required.");
  if (messages.length > LIMITS.maxMessages) throw new Invalid("The conversation is too long. Start a new one.");

  const budget = { textChars: 0, images: 0 };
  const clean = messages.map((message, i) => parseMessage(message, i, mode, budget));

  if (budget.images > LIMITS.maxImagesPerRequest) {
    throw new Invalid(`Send at most ${LIMITS.maxImagesPerRequest} photos at a time.`);
  }
  if (budget.textChars > LIMITS.maxTextChars) throw new Invalid("That is too much text for one request.");
  return { mode, model, messages: clean };
}

function parseMessage(message: unknown, index: number, mode: Mode, budget: { textChars: number; images: number }): Message {
  if (!isObject(message)) throw new Invalid("Each message must be an object.");
  const { role, content } = message;
  if (role !== "user" && role !== "assistant") throw new Invalid("Message roles must be user or assistant.");
  if (index === 0 && role !== "user") throw new Invalid("The first message must come from the user.");

  if (typeof content === "string") {
    if (content.trim().length === 0) throw new Invalid("Messages cannot be empty.");
    budget.textChars += content.length;
    return { role, content };
  }
  if (!Array.isArray(content) || content.length === 0) throw new Invalid("Message content is missing.");

  const allowed = ALLOWED_BLOCKS[mode][role];
  const blocks = content.map((block) => {
    if (!isObject(block) || typeof block.type !== "string" || !allowed.includes(block.type)) {
      throw new Invalid("This message type is not allowed here.");
    }
    return parseBlock(block, budget);
  });
  return { role, content: blocks } as Message;
}

function parseBlock(block: Record<string, unknown>, budget: { textChars: number; images: number }): Block {
  switch (block.type) {
    case "text":
      return { type: "text", text: text(block.text, budget) };

    case "image": {
      const source = block.source;
      if (!isObject(source) || source.type !== "base64" || typeof source.data !== "string" ||
          !IMAGE_TYPES.includes(source.media_type as ImageType)) {
        throw new Invalid("Images must be base64 JPEG, PNG, WebP or GIF.");
      }
      if (source.data.length > LIMITS.maxImageBase64Chars) throw new Invalid("The photo is too large.");
      if (!matchesImage(source.data, source.media_type as ImageType)) {
        throw new Invalid("The photo data does not match its type.");
      }
      budget.images++;
      return { type: "image", source: { type: "base64", media_type: source.media_type as ImageType, data: source.data } };
    }

    case "tool_result": {
      if (typeof block.tool_use_id !== "string") throw new Invalid("Tool results need a tool_use_id.");
      // Results come from the phone's own tools, so plain text is all they need. Anything richer
      // (images, documents) would slip past the checks above.
      const content = block.content;
      const value = typeof content === "string"
        ? text(content, budget)
        : Array.isArray(content) && content.every((c) => isObject(c) && c.type === "text")
        ? content.map((c) => ({ type: "text" as const, text: text((c as Record<string, unknown>).text, budget) }))
        : null;
      if (value === null) throw new Invalid("Tool results must be text.");
      return { type: "tool_result", tool_use_id: block.tool_use_id, content: value, ...(block.is_error === true ? { is_error: true } : {}) };
    }

    case "tool_use":
      if (typeof block.id !== "string" || typeof block.name !== "string" || !isObject(block.input)) {
        throw new Invalid("Malformed tool call.");
      }
      budget.textChars += JSON.stringify(block.input).length;
      return { type: "tool_use", id: block.id, name: block.name, input: block.input };

    case "thinking":
      // Claude's reasoning, returned unchanged. The API checks the signature, so it cannot be forged.
      if (typeof block.thinking !== "string" || typeof block.signature !== "string") {
        throw new Invalid("Malformed thinking block.");
      }
      budget.textChars += block.thinking.length;
      return { type: "thinking", thinking: block.thinking, signature: block.signature };

    case "redacted_thinking":
      if (typeof block.data !== "string") throw new Invalid("Malformed thinking block.");
      return { type: "redacted_thinking", data: block.data };

    default:
      throw new Invalid("This message type is not allowed here.");
  }
}

function text(value: unknown, budget: { textChars: number }): string {
  if (typeof value !== "string") throw new Invalid("Text blocks need text.");
  budget.textChars += value.length;
  return value;
}

const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

// The first bytes of each format, checked on the decoded start of the data, so a file that only
// claims to be a JPEG is refused here rather than billed and refused by the API.
function matchesImage(data: string, type: ImageType): boolean {
  if (data.length % 4 !== 0 || !BASE64.test(data)) return false;
  let head: Uint8Array;
  try {
    head = Uint8Array.from(atob(data.slice(0, 16)), (c) => c.charCodeAt(0));
  } catch {
    return false;
  }
  const starts = (sig: number[], offset = 0) => sig.every((b, i) => head[offset + i] === b);
  switch (type) {
    case "image/jpeg":
      return starts([0xff, 0xd8, 0xff]);
    case "image/png":
      return starts([0x89, 0x50, 0x4e, 0x47]);
    case "image/gif":
      return starts([0x47, 0x49, 0x46, 0x38]);
    case "image/webp":
      return starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8);
  }
}
