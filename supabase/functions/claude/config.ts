// Every limit and model choice the function enforces lives here, so the app can never ask for
// more than the server allows. Change a number here, redeploy, and every client follows.

// serverFallback: Opus and Sonnet support server-side refusal fallbacks; Haiku does not.
export const MODELS = {
  "claude-haiku-5-5": { serverFallback: false },
  "claude-sonnet-5-5": { serverFallback: true },
  "claude-opus-5-5": { serverFallback: true },
} as const;

export type ModelId = keyof typeof MODELS;

export const MODES = ["chat", "vision", "extract", "agent"] as const;
export type Mode = (typeof MODES)[number];

// Output ceilings per mode. Thinking tokens count toward these, so they are generous for the task
// but still cap what one request can cost.
export const MAX_TOKENS: Record<Mode, number> = {
  chat: 8000,
  vision: 6000,
  extract: 4000,
  agent: 6000,
};

// Effort trades depth for speed and spend. Chat and extraction are routine; photos and tool
// planning get one level more.
export const EFFORT: Record<Mode, "low" | "medium"> = {
  chat: "low",
  vision: "medium",
  extract: "low",
  agent: "medium",
};

export const LIMITS = {
  perUserPerMinute: 20,
  perUserPerDay: 200,
  // Anonymous sign-in means anyone can make new users, so one network (hashed IP) has its own
  // ceiling, and the whole project has a final one.
  perIpPerDay: 400,
  projectPerDay: 2000,
  // Request counts alone would let someone send only the most expensive calls, so input plus
  // output tokens are capped per day as well.
  userTokensPerDay: 400_000,
  projectTokensPerDay: 4_000_000,
  maxMessages: 60,
  maxTextChars: 120_000,
  // Base64 characters for one image, about 2.6 MB of image bytes. The app resizes to 1568 px
  // JPEG first, which is usually well under 1 MB.
  maxImageBase64Chars: 3_500_000,
  maxImagesPerRequest: 4,
  // Checked from Content-Length before the body is parsed.
  maxBodyBytes: 16_000_000,
};

export const SERVER_FALLBACK_BETA = "server-side-fallback-2026-07-01";
