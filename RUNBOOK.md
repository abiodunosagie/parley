# Parley runbook

How to run the app, find errors, and change the backend. Read this before you touch anything.

## How the pieces fit

```
Flutter app (lib/)                     Supabase project                          Anthropic API
  Chat, Look, Read, Tasks,    --->  Edge function "claude"            --->   claude-opus-5-5
  Rewrite, Receipts, Extract
  email + password accounts        checks the session, the body,            claude-sonnet-5-5
  holds no Parley key              the rate limits, holds the key           claude-haiku-5-5
                                   Edge function "delete-account"
```

- The app only knows the Supabase URL and the publishable key (`config/parley.json`). Both are
  public by design.
- The Claude key is a Supabase secret named `ANTHROPIC_API_KEY`. It never ships in the app.
- Own keys: Account > Claude API key lets a user add their own Anthropic key. The app keeps it in
  the Keychain (iOS, this device only, no iCloud sync) or Keystore-backed storage (Android), per
  account, and deletes it whenever that account signs out or is deleted (`app/session_reset.dart`,
  account clean-ups in `main.dart`). It is sent as `api_key` in the JSON body, never a header,
  because platform request logs record headers. The function checks its shape, uses it for that
  one request, and never stores or logs it (`logFailure` in index.ts blanks it). Those rows are
  marked `own_key`: the per-minute limit and a separate daily count (`ownKeyPerUserPerDay`) apply,
  and they never count toward the shared daily, network, search or project budgets. A rejected own
  key comes back as 403 (not 401, so the app does not retry), an empty balance as 402.
- Deploy order for backend changes like this one: `supabase db push` first, then
  `supabase functions deploy claude`, then ship the app. The migration keeps the old function
  working (`p_own_key` defaults to false); the new function needs the migration.
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
| Chat | Streaming, model switch, stop | `lib/features/conversation/` | `streamReply` in `claude.ts` |
| Look | Vision (base64 image blocks) | `lib/features/conversation/` (`look_screen.dart`) | same stream, `vision` mode |
| Extract | Structured output (JSON schema) | `lib/features/extract/` | `extractJobPost`, `JOB_POST_SCHEMA` |
| Tasks | Tool use, agent loop on the phone | `lib/features/tasks/` | `agentTurn`, `AGENT_TOOLS` |

Folder layout and the layering rules: `docs/CODE_TOUR.md`.

## Keyboard in the iOS Simulator

The Mac keyboard types straight into the simulator, so the on-screen keyboard stays hidden while
Simulator > I/O > Keyboard > Connect Hardware Keyboard is ticked. Tap the message box first, then
press Cmd+K to show it, or untick that option. On a real phone the keyboard opens on tap
(`test/core/widgets/keyboard_dismiss_test.dart` proves the app side).
