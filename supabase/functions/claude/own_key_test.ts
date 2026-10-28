// The user's own key: which header values are accepted, and the words a rejected key turns into.
import { assert, assertEquals, assertFalse } from "jsr:@std/assert@1";
import Anthropic from "npm:@anthropic-ai/sdk@1.1.0";
import { publicError } from "./claude.ts";
import { OWN_KEY_PATTERN } from "./config.ts";

const headers = new Headers();

Deno.test("own key: accepts the shape of an Anthropic key", () => {
  assert(OWN_KEY_PATTERN.test("sk-ant-api03-" + "a".repeat(40)));
});

Deno.test("own key: refuses anything else", () => {
  for (const value of ["", "sk-ant-short", "sk-proj-" + "a".repeat(40), "sk-ant-" + "a".repeat(40) + "\nx", "sk-ant-" + "a".repeat(300)]) {
    assertFalse(OWN_KEY_PATTERN.test(value), value);
  }
});

Deno.test("own key: a rejected key is a 403 the user can fix, never a 401", () => {
  const error = new Anthropic.AuthenticationError(401, {}, "invalid x-api-key", headers);
  assertEquals(publicError(error, true), { message: "Claude did not accept your API key. Check it under Account.", status: 403 });
});

Deno.test("own key: an empty balance says so", () => {
  // The body as the API sends it; the SDK puts it into the error's message.
  const body = {
    type: "error",
    error: { type: "invalid_request_error", message: "Your credit balance is too low to access the Anthropic API." },
  };
  const error = new Anthropic.BadRequestError(400, body, undefined, headers);
  assertEquals(publicError(error, true).status, 402);
});

Deno.test("project key: a rejected key stays a server problem", () => {
  const error = new Anthropic.AuthenticationError(401, {}, "invalid x-api-key", headers);
  assertEquals(publicError(error).status, 503);
});
