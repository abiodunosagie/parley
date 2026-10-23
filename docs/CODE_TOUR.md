# Code tour

Every Dart file starts with a `// FILE:` header that says what it does and, for the key files,
what to read next. Start at `lib/main.dart` and follow the trail, or use this page.

## The architecture in one picture

```
lib/
  main.dart                 entry point: Supabase, dependency wiring, runApp
  app/                      the app widget, GoRouter routes, per-account reset
  core/                     shared by every feature, never imports a feature
    config/                 build-time settings (Supabase URL + publishable key)
    network/                ClaudeClient (talks to the `claude` edge function), SSE parsing, CancelToken
    errors/                 AppException, the words shown for failures (plain), error_log (logs + words)
    models/                 the Claude model list
    state/                  the selected model, shared by every feature
    session/                the session token and account clean-up hooks (overridden in main.dart)
    supabase/               the one Supabase client, as a provider tests can replace
    theme/                  palette, Material theme, Markdown theme, sizes
    widgets/                reusable widgets: Composer, StarterButtons, UserBubble, Notice, ...
  features/<feature>/
    domain/                 plain Dart: entities, repository interfaces, services (the logic)
    data/                   implementations: Supabase, SharedPreferences, notifications, ClaudeClient
    presentation/           Riverpod controllers (state), screens, feature widgets
```

Rules, enforced by `test/architecture_test.dart` on every test run:

- `domain/` is plain Dart: nothing from Flutter, Riverpod, Supabase, `data/` or `presentation/`
  (entities use `package:meta` for `@immutable`).
- A feature uses another feature only through three shared pieces: the signed-in user
  (`auth/.../current_user_provider.dart`), the account button, and the shared app bar
  (`home/.../feature_app_bar.dart`).
- `core/` never imports a feature.
- `presentation/` reaches `data/` only through `*_repository_impl.dart`, where each repository's
  Riverpod provider lives.
- No screen or widget talks to Supabase or HTTP.
- No file passes 300 lines.

State is Riverpod everywhere. Each screen watches one controller, and the rule for its state is:

- a **sealed set of states** when each state carries different data (`ExtractIdle`, `Extracting`,
  `ExtractDone(job)`, `ExtractFailed(message)`; the account sheet; the sign-in submit status);
- an **immutable class with `copyWith`** when the screen always shows the same fields plus a status
  (the chat and agent conversations);
- an **`AsyncNotifier`** when the data loads from storage (the task list), so loading and errors are
  explicit states instead of an empty list.

Widgets keep only widget plumbing such as `TextEditingController` and `AnimationController`.

Three small trade-offs, on purpose:

- `main.dart` overrides `accessTokenProvider` and `accountCleanupsProvider`. That is how `core/`
  gets the session token and how deleting an account clears the tasks, without core or auth
  importing other features.
- `ReplyEvent` (domain) mirrors the stream events in `core/network/sse.dart`. The copy keeps the
  conversation logic independent of how the server streams, so the transport can change alone.
- `PhoneToolActions` lives in `tasks/presentation/providers/`: it connects the domain's
  `ToolActions` to the live task list controller, so it is composition glue, not data access.

## 1. What happens when you tap Send in Chat

```
ChatScreen                                   features/conversation/presentation/screens/chat_screen.dart
  Composer.onSend("Hi")                      core/widgets/composer.dart
    -> ConversationController.send("Hi")    features/conversation/presentation/providers/conversation_controller.dart
         adds your bubble + an empty reply bubble
         -> ConversationRepository.reply()  features/conversation/data/repositories/conversation_repository_impl.dart
              -> ClaudeClient.stream(mode: chat)        core/network/claude_client.dart
                   POST https://<project>.supabase.co/functions/v1/claude
                   Authorization: Bearer <your session token>
                     -> edge function                   supabase/functions/claude/index.ts
                          1. body too big?  2. session real?  3. body valid?  4. under the limits?
                          5. call Claude, streaming
                   <- data: {"type":"text","text":"Hel"} ... data: {"type":"done", ...}
              <- parseSse turns lines into TextDelta / StreamDone   core/network/sse.dart
         <- mapped to domain ReplyText / ReplyDone
       each ReplyText appends to the reply bubble -> the screen rebuilds -> text "types out"
```

Look is the same path through `LookController` (a `ConversationController` with the photo), with
the photo as an image block on your first message (`data/mappers/chat_message_mapper.dart`).
Photos come from `PhotoRepository`; when one cannot be used the reason shows as the notice.

## 2. Extract (structured output)

`ExtractController.extract()` calls `ExtractRepository.extractJobPost()`. The server adds
`output_config.format` with `JOB_POST_SCHEMA` (`supabase/functions/claude/schemas.ts`), which forces
Claude's answer to be JSON in exactly that shape, so it always parses into a `JobPost`.

## 3. Tasks (tool use, the agent loop)

The loop itself is plain Dart in `features/tasks/domain/services/agent_loop.dart`:

```
AgentLoop.run("Add milk tomorrow")
  round 1: AgentRepository.next() -> stop_reason "tool_use": [tool_use list_tasks {}]
           ToolExecutor.run("list_tasks") -> {"today": "...", "tasks": []}
           send the result back as a tool_result block
  round 2: [tool_use add_task {title: "Milk", due_date: "2026-10-24", ...}]
           ToolExecutor adds the task on the phone
  round 3: stop_reason "end_turn": "Added milk for tomorrow."
```

`AgentController` (presentation) only turns the loop's progress into screen state. Account
deletion works the same way: the steps live in `auth/domain/services/delete_account.dart`, and the
account sheet only shows where they are. The tools are
declared on the server (`AGENT_TOOLS`), so an edited app cannot add new ones; they run on the phone
(`domain/services/tool_executor.dart` through `presentation/providers/phone_tool_actions.dart`).

## 4. Sign in and navigation

`app/router/app_router.dart` is the only place that decides which screen shows. Signed out: the
sign-in screen. Signed in: the four tabs in a `StatefulShellRoute`, each keeping its own screen
alive. The router re-checks on every sign-in or sign-out. `app/session_reset.dart` clears the
previous account's conversations when the account changes.

## 5. Tests

```
test/core/            network client, SSE parsing, keyboard dismiss
test/features/...     mirrors lib/features: entities, mappers, validators, tools, the agent loop,
                      controllers (chat streaming and races, tasks, sign-in), repositories, delete flow
test/helpers/         shared fakes (an account system and a task store in memory)
test/app/             the whole app with the router, signed in and out, every tab, light and dark
test/architecture_test.dart   the layering rules above
supabase/functions/claude/validate_test.ts   server-side request validation
```
