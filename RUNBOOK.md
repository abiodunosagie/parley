# Parley runbook

How to run the app, find errors, and change the backend. Read this before you touch anything.

## How the pieces fit

```
Flutter app (lib/)                     Supabase project                          Anthropic API
  Chat, Look, Extract, Tasks  --->  Edge function "claude"            --->   claude-opus-5-5
  email + password accounts        checks the session, the body,            claude-sonnet-5-5
  holds NO Claude key              the rate limits, holds the key           claude-haiku-5-5
                                   Edge function "delete-account"
```

- The app only knows the Supabase URL and the publishable key (`config/parley.json`). Both are
  public by design.
- The Claude key is a Supabase secret named `ANTHROPIC_API_KEY`. It never ships in the app.
- Every call is logged in `public.claude_requests`. One locked database function
  (`claim_claude_request`) checks the limits and records the call in a single step: 20 requests a
  minute, 200 a day and 150k tokens a day per user, 400 a day per network, and 2000 requests or
  1M tokens a day for the whole project (`supabase/functions/claude/config.ts`).
- Accounts are Supabase email and password. Email confirmation is off, because Supabase's built-in
  mailer only sends a few emails an hour; add your own SMTP (for example Resend) before turning it on.
- Settings > Delete account calls `delete-account`, which deletes the user and their usage rows.

## Run the app (IntelliJ)

1. Open the `parley` folder in IntelliJ.
2. Run > Edit Configurations > the `main.dart` Flutter config.
3. In **Additional run args** put: `--dart-define-from-file=config/parley.json`
4. Pick the iPhone simulator or your phone in the device list, then Run.

Without step 3 the app opens on a screen that says it needs its config. That is on purpose.

Terminal equivalent:

```bash
flutter run --dart-define-from-file=config/parley.json
```

`config/parley.json` is gitignored. A fresh clone copies `config/parley.example.json` and fills in
its own project's URL and publishable key.

## Where errors show up

| What broke | Where to look |
| --- | --- |
| Dart code (red screen, exceptions) | IntelliJ Run console. Unexpected errors are printed as `Parley <feature> error: ...`. |
| A message under the composer | That text came from the server, in plain words. The real cause is in the function logs. |
| The function itself | Supabase dashboard > Edge Functions > claude > Logs, or `supabase functions logs claude` |
| Static problems | `flutter analyze` (must say "No issues found") |
| Logic | `flutter test` and `deno test supabase/functions/claude/` |

## Set up your own backend (fresh clone)

```bash
supabase login
supabase projects create parley      # or use an existing project
supabase link --project-ref <ref>
supabase db push --linked            # creates claude_requests and claim_claude_request
supabase config push                 # email sign-up on, anonymous off, 8-character passwords
supabase functions deploy claude
supabase functions deploy delete-account
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
cp config/parley.example.json config/parley.json   # then fill in the URL and publishable key
```

## Change the backend

```bash
supabase functions deploy claude     # after editing supabase/functions/claude/*
supabase db push --linked            # after adding a file in supabase/migrations/
```

Check before deploying:

```bash
cd supabase/functions/claude && deno check index.ts && deno test
```

## Set or rotate the Claude key

Make a key at console.anthropic.com > API Keys, then:

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

Set a monthly spend limit on the key in the console as well. The function's rate limits stop
abuse; the console limit is the last line of defence for the bill.

## The four features and where they live

| Tab | Claude feature | App code | Server code |
| --- | --- | --- | --- |
| Chat | Streaming, model switch, stop | `lib/features/chat/` | `streamReply` in `claude.ts` |
| Look | Vision (base64 image blocks) | `lib/features/vision/` | same stream, `vision` mode |
| Extract | Structured output (JSON schema) | `lib/features/extract/` | `extractJobPost`, `JOB_POST_SCHEMA` |
| Tasks | Tool use, agent loop on the phone | `lib/features/agent/` | `agentTurn`, `AGENT_TOOLS` |
