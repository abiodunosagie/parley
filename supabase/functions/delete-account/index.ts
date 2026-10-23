// Deletes the signed-in user's own account (Apple requires in-app account deletion for any app
// with sign-up). The user can only ever delete themselves: the id comes from their verified
// session, never from the request body. Their claude_requests rows go with it (on delete cascade).
import { createClient } from "jsr:@supabase/supabase-js@2.118.0";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Use POST." }, 405);

  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "Sign in first." }, 401);
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return json({ error: "Your session expired. Sign in again." }, 401);

  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) {
    console.error("delete user failed", deleteError.message);
    return json({ error: "Could not delete the account. Try again." }, 500);
  }
  return json({ deleted: true });
});
