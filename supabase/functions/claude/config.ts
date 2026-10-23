// Every limit and model choice the function enforces lives here, so the app can never ask for
// more than the server allows. Change a number here, redeploy, and every client follows.

// serverFallback: Opus and Sonnet support server-side refusal fallbacks; Haiku does not.
export const MODELS = {
  "claude-haiku-5-5": { serverFallback: false },
  "claude-sonnet-5-5": { serverFallback: true },
  "claude-opus-5-5": { serverFallback: true },
} as const;

export type ModelId = keyof typeof MODELS;

// Streaming modes send text as it is written; the others return one finished JSON answer.
export const MODES = ["chat", "vision", "document", "rewrite", "extract", "receipt", "agent"] as const;
export const STREAMING_MODES = ["chat", "vision", "document", "rewrite"] as const;
export type Mode = (typeof MODES)[number];

// Output ceilings per mode. Thinking tokens count toward these, so they are generous for the task
// but still cap what one request can cost.
export const MAX_TOKENS: Record<Mode, number> = {
  chat: 8000,
  vision: 6000,
  document: 8000,
  rewrite: 4000,
  extract: 4000,
  receipt: 4000,
  agent: 6000,
};

// Effort trades depth for speed and spend. Chat, rewriting and extraction are routine; photos,
// receipts, documents and tool planning get one level more.
export const EFFORT: Record<Mode, "low" | "medium"> = {
  chat: "low",
  vision: "medium",
  document: "medium",
  rewrite: "low",
  extract: "low",
  receipt: "medium",
  agent: "medium",
};

// Modes whose replies show Claude's summarized reasoning in the app. Rewriting and the two
// structured modes only show the result.
export const SHOW_THINKING: readonly Mode[] = ["chat", "vision", "document", "agent"];

// Web search is a server tool: Anthropic runs the searches inside the same request. Each search
// is billed ($10 per 1,000), so one reply may search at most this many times.
export const WEB_SEARCH_MAX_USES = 3;

export const LIMITS = {
  perUserPerMinute: 20,
  perUserPerDay: 200,
  // Anyone can create an account, so one network (hashed IP) has its own ceiling, and the
  // whole project has a final one.
  perIpPerDay: 400,
  projectPerDay: 2000,
  // Request counts alone would let someone send only the most expensive calls, so input plus
  // output tokens are capped per day as well.
  userTokensPerDay: 150_000,
  // About $20 a day at worst on Opus (all output), a fifth of the $100 starter credit.
  projectTokensPerDay: 1_000_000,
  maxMessages: 60,
  maxTextChars: 120_000,
  // Base64 characters for one image, about 2.6 MB of image bytes. The app resizes to 1568 px
  // JPEG first, which is usually well under 1 MB.
  maxImageBase64Chars: 3_500_000,
  maxImagesPerRequest: 4,
  // One PDF, about 6 MB of file bytes. Every follow-up question sends it again, and each page
  // costs 1,500 to 3,000 input tokens, so the daily token cap stops very long documents.
  maxPdfBase64Chars: 8_000_000,
  maxDocumentsPerRequest: 1,
  // Opaque data Claude hands back for replay (web search results, signed thinking). Counted
  // apart from text because it is large and cannot be read or forged.
  maxOpaqueChars: 1_500_000,
  // Checked from Content-Length before the body is parsed.
  maxBodyBytes: 16_000_000,
};

export const SERVER_FALLBACK_BETA = "server-side-fallback-2026-07-01";
