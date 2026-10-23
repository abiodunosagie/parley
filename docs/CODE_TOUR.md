# Code tour

Every Dart file starts with a `// FILE:` header that says what it does and, for the key files,
what to read next. Start at `lib/main.dart` and follow the trail, or use this page.

## The architecture in one picture

```
lib/
  main.dart                 entry point: Supabase, dependency wiring, runApp
  app/                      the app widget, the launch splash, GoRouter routes and the gate, per-account reset
  core/                     shared by every feature, never imports a feature
    config/                 build-time settings (Supabase URL + publishable key)
    network/                ClaudeClient (talks to the `claude` edge function), SSE parsing, CancelToken
    errors/                 AppException, the words shown for failures (plain), error_log (logs + words)
    models/                 the Claude model list, SavedSummary (one line in a history list)
    state/                  the selected model; saved_history.dart (history lists + controller mixin)
    session/                the session token and account clean-up hooks (overridden in main.dart)
    storage/                LocalStore (history on the phone), SavedCollection, the preferences provider
    speech/                 on-device dictation: SpeechService and VoiceInput
    media/                  photo picking and file-type checks shared by Look and Receipts
    platform/               opening a cited web page in the browser
    supabase/               the one Supabase client, as a provider tests can replace
    theme/                  palette, Material theme, Markdown theme, sizes
    widgets/                Composer (with the mic), HistorySheet, ReasoningPanel, VoiceWave, ...
  features/<feature>/
    domain/                 plain Dart: entities, repository interfaces, services (the logic)
    data/                   implementations: Supabase, local storage, notifications, ClaudeClient
    presentation/           Riverpod controllers (state), screens, feature widgets
```

The features, and the Claude API feature each one shows:

| Tab | Feature folder | Claude API feature |
| --- | --- | --- |
| Chat | `conversation` | streaming, summarized reasoning, web search with cited sources |
| Look | `conversation` | vision (a photo on the first message) |
| Read | `conversation` | PDF documents with citations (page and quote for every claim) |
| Tasks | `tasks` | tool use: an agent loop whose tools run on the phone |
| Tools: Rewrite | `rewrite` | streaming text with a fixed instruction |
| Tools: Receipts | `receipt` | vision plus structured output (a fixed JSON shape) |
| Tools: Extract | `extract` | structured output from pasted text |
| Welcome pages | `onboarding` | shown once per install, before sign-in |

Rules, enforced by `test/architecture_test.dart` on every test run:

- `domain/` is plain Dart: nothing from Flutter, Riverpod, Supabase, `data/` or `presentation/`
  (entities use `package:meta` for `@immutable`).
- A feature uses another feature only through three shared pieces: the signed-in user
  (`auth/.../current_user_provider.dart`), the account button, and the shared app bar
  (`home/.../feature_app_bar.dart`).
- `core/` never imports a feature.
- From `app/`, a feature imports only `app/router/app_routes.dart`, for the paths it opens (the
  Tools list opens its three tools by route).
- `presentation/` reaches `data/` only through `*_repository_impl.dart`, where each repository's
  Riverpod provider lives.
- No screen or widget talks to Supabase or HTTP.
- No file passes 300 lines.

State is Riverpod everywhere. Each screen watches one controller, and the rule for its state is:

- a **sealed set of states** when each state carries different data (`ExtractIdle`, `Extracting`,
  `ExtractDone(job)`, `ExtractFailed(message)`; the receipt scan; the account sheet; the sign-in
  submit status);
- an **immutable class with `copyWith`** when the screen always shows the same fields plus a status
  (the Chat, Look and Read conversations, the Tasks conversation, Rewrite);
- an **`AsyncNotifier`** when the data loads from storage (the task list), so loading and errors are
  explicit states instead of an empty list.

Widgets keep only widget plumbing such as `TextEditingController`, `AnimationController` and
`VoiceInput` (dictation into one text box).

Every controller that starts a request keeps the `CancelToken` of the request that owns the
screen. Starting over, opening history or deleting drops it, so a request still finishing can
never write into what you opened since.

Small trade-offs, on purpose:

- `main.dart` overrides `accessTokenProvider` and `accountCleanupsProvider`. That is how `core/`
  gets the session token and how deleting an account clears the tasks and all saved history,
  without core or auth importing other features.
- `ReplyEvent` (domain) mirrors the stream events in `core/network/sse.dart`. The copy keeps the
  conversation logic independent of how the server streams, so the transport can change alone.
- `PhoneToolActions` lives in `tasks/presentation/providers/`: it connects the domain's
  `ToolActions` to the live task list controller, so it is composition glue, not data access.
- Claude's replies are kept twice: as display fields (text, reasoning, searches, sources) and as
  `replay`, the turn exactly as the API returned it. The next request sends `replay` back
  unchanged, because thinking signatures and encrypted search results only work untouched.

## 1. What happens when you tap Send in Chat

```
ChatScreen                                   features/conversation/presentation/screens/chat_screen.dart
  Composer.onSend("Hi")                      core/widgets/composer.dart
    -> ConversationController.send("Hi")    features/conversation/presentation/providers/conversation_controller.dart
         adds your bubble + an empty reply bubble, locks the conversation to the selected model
         -> ConversationRepository.reply()  features/conversation/data/repositories/conversation_repository_impl.dart
              -> ClaudeClient.stream(mode: chat, webSearch: on/off)   core/network/claude_client.dart
                   POST https://<project>.supabase.co/functions/v1/claude
                   Authorization: Bearer <your session token>
                     -> edge function                   supabase/functions/claude/index.ts
                          1. body too big?  2. session real?  3. body valid?  4. under the limits?
                          5. search budget / document size  6. call Claude, streaming
                   <- data: {"type":"thinking"} {"type":"search"} {"type":"text"} {"type":"source"}
                      ... data: {"type":"done","content":[Claude's whole turn]}
              <- parseSse turns lines into events                core/network/sse.dart
         <- mapped to domain ReplyThinking / ReplySearch / ReplyText / ReplySource / ReplyDone
       each event updates the reply bubble -> the screen rebuilds -> reasoning, then text "types out"
       when done: keep Claude's turn for replay, save the conversation to history
```

Look and Read are the same path through `LookController` and `ReadController`, with the photo
or the PDF on your first message (`data/mappers/chat_message_mapper.dart`). For Read the server
turns citations on, so the reply streams `source` events with the page and the quoted words.

On the server (`supabase/functions/claude/claude.ts`), a long search turn can come back as
`pause_turn`; the function resumes it by sending the paused turn back, at most twice, and never
past three searches in total. The per-network limit hashes `CF-Connecting-IP`, which Cloudflare sets and clients cannot fake.
A `Meter` records what each request spends as the API reports it,
and `index.ts` logs it in a `finally`, so a request the app abandons still counts against the
limits.

## 2. One-request tools: Extract, Receipts, Rewrite

`ExtractController.extract()` calls `ExtractRepository.extractJobPost()`. The server adds
`output_config.format` with `JOB_POST_SCHEMA` (`supabase/functions/claude/schemas.ts`), which forces
Claude's answer to be JSON in exactly that shape, so it always parses into a `JobPost`.

Receipts work the same way with a photo and `RECEIPT_SCHEMA`; the app then adds the items up by
category (`receipt/domain/entities/receipt.dart`) and flags a printed total that does not match.

Rewrite streams like Chat but sends a single instruction (`rewrite/domain/entities/rewrite_style.dart`).
"Show changes" runs a word-level diff on the phone (`rewrite/domain/services/word_diff.dart`).

## 3. Tasks (tool use, the agent loop)

The loop itself is plain Dart in `features/tasks/domain/services/agent_loop.dart`:

```
AgentLoop.run("Add milk tomorrow")
  round 1: AgentRepository.next() -> stop_reason "tool_use": [thinking] [tool_use list_tasks {}]
           ToolExecutor.run("list_tasks") -> {"today": "...", "tasks": []}
           send the result back as a tool_result block
  round 2: [tool_use add_task {title: "Milk", due_date: "2026-10-24", ...}]
           ToolExecutor adds the task on the phone
  round 3: stop_reason "end_turn": "Added milk for tomorrow."
```

The transcript only grows by whole steps, and the screen shows exactly those steps. A tool round
goes in with every result (after Stop, the skipped calls are answered "Not run"), a failed or
cut-short answer is neither shown nor kept, and your message stays. So the screen, saved history
and what Claude knows always match.

`AgentController` (presentation) only turns the loop's progress into screen state, including
Claude's reasoning for each round, and saves the conversation (lines and transcript) so it can be
reopened and carried on. Account deletion works the same way: the steps live in
`auth/domain/services/delete_account.dart`, and the account sheet only shows where they are. The
tools are declared on the server (`AGENT_TOOLS`), so an edited app cannot add new ones; they run
on the phone (`domain/services/tool_executor.dart` through `presentation/providers/phone_tool_actions.dart`).

## 4. History

Everything you make is saved on the phone, per account, in the app's support folder
(`core/storage/local_store.dart`):

```
history/<userId>/<feature>/index.json     what the History sheet lists
history/<userId>/<feature>/<id>.json      one item, with its own summary (so a damaged index rebuilds)
history/<userId>/<feature>/<id>/<file>    its photo or PDF
```

Each feature's history repository is a thin layer over `SavedCollection`
(`core/storage/saved_collection.dart`). Controllers use the `SavedHistory` mixin
(`core/state/saved_history.dart`) to open, save and delete, so a storage failure is logged and never
breaks the screen. Deleting your account deletes the whole `history/<userId>` folder.

History never leaves the phone. On iOS the `history` folder is marked as excluded from iCloud
backup through the `parley/storage` channel in `ios/Runner/AppDelegate.swift`, the app's only
native code; Android backups are turned off for the app in its manifest.

## 5. Voice input

The mic in the composer (and in the Rewrite and Extract text boxes) uses the phone's own speech
recognition (`core/speech/speech_service.dart`). Words appear in the box as you speak while
`VoiceWave` moves with your voice; nothing is sent until you tap Send.

## 6. Launch, welcome, sign in and navigation

`app/router/app_gate.dart` is one pure function that decides which screen may show, in launch
order: the splash (`app/launch/launch_screen.dart`, the mark's halves meet once, after the first
frame is drawn), then the welcome pages (`features/onboarding`, once per install: a versioned
flag in SharedPreferences, opened in `main.dart` before the first frame), then sign-in, then the
app. `app/router/app_router.dart` re-runs the gate whenever the launch finishes, the welcome pages
are done, or the signed-in user changes, and hands each step over with a cross-fade.

Signed in: the five tabs in a `StatefulShellRoute`, each keeping its own screen alive; Tools opens
Rewrite, Receipts and Extract on top of its list.

Creating an account asks for a first and last name (`auth/domain/validators/auth_validators.dart`),
saved in the account's user metadata; Chat greets you with it, and the account sheet lets older
accounts add or change it. `app/session_reset.dart` clears the previous account's screens when the
account changes.

## 7. Tests

```
test/core/            network client, SSE parsing, keyboard, history store, history sheet, dictation
test/features/...     mirrors lib/features: entities, mappers, validators, tools, the agent loop,
                      word diff, receipts, controllers (chat streaming, history, model lock, races,
                      receipt scans), repositories, delete flow
test/helpers/         shared fakes (accounts, tasks, saved history and dictation, all in memory)
test/app/             the gate, and the whole app: first run (splash, welcome, sign-in), signed in and out,
                      every tab and tool, light and dark, a small phone with large text
test/architecture_test.dart   the layering rules above
supabase/functions/claude/validate_test.ts   server-side request and replay validation
integration_test/     on a Simulator: README screenshots against the live backend, and the first run
```
