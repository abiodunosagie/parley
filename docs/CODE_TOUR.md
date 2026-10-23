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
    errors/                 AppException, the words shown for failures
    models/ state/          the Claude model list and the selected model
    session/                how network code gets the session token (overridden in main.dart)
    theme/                  palette, Material theme, Markdown theme, sizes
    widgets/                reusable widgets: Composer, StarterButtons, UserBubble, Notice, ...
  features/<feature>/
    domain/                 plain Dart: entities, repository interfaces, services (the logic)
    data/                   implementations: Supabase, SharedPreferences, notifications, ClaudeClient
    presentation/           Riverpod controllers (state), screens, feature widgets
```

Rules, enforced by `test/architecture_test.dart` on every test run:

- `domain/` imports nothing from Flutter UI, Riverpod, Supabase, `data/` or `presentation/`.
- `core/` never imports a feature.
- `presentation/` reaches `data/` only through `*_repository_impl.dart`, where each repository's
  Riverpod provider lives.
- No screen or widget talks to Supabase or HTTP.
- No file passes 300 lines.

State is Riverpod everywhere: each screen watches one controller (a `Notifier`) whose state is an
immutable class or a sealed set of explicit states (for example `ExtractIdle`, `Extracting`,
`ExtractDone`, `ExtractFailed`). Widgets keep only widget plumbing such as `TextEditingController`.

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

Look is the same path with `ConversationKind.vision` and the photo as an image block on your
first message (`data/mappers/chat_message_mapper.dart`). Photos come from `PhotoRepository`.

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

`AgentController` (presentation) only turns the loop's progress into screen state. The tools are
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
test/features/...     mirrors lib/features: entities, mappers, validators, tools, the agent loop
test/app/             the whole app with the router, signed in and out, every tab, light and dark
test/architecture_test.dart   the layering rules above
supabase/functions/claude/validate_test.ts   server-side request validation
```
