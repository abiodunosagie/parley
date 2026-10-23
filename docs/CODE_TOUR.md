# Code tour

Read the code in this order. Every Dart file starts with a `// FILE:` header that says what it
does and what to read next, so you can also open any file and follow the trail from there.

## 1. What happens when you tap Send in Chat

```
ChatScreen (chat_screen.dart)
  Composer.onSend("Hi")
    -> ConversationController.send("Hi")             lib/features/conversation/conversation.dart
         adds your bubble + an empty reply bubble
         -> ClaudeApi.stream(mode: chat, model, messages)   lib/core/claude_api.dart
              POST https://<project>.supabase.co/functions/v1/claude
              Authorization: Bearer <your session token>
                -> edge function index.ts                   supabase/functions/claude/index.ts
                     1. is the body too big?
                     2. is the session real?           (auth.getUser)
                     3. is the body valid?             (validate.ts)
                     4. is this user under the limits? (claim_claude_request, one locked SQL call)
                     5. call Claude, streaming          (claude.ts -> Anthropic API)
                <- data: {"type":"text","text":"Hel"}
                <- data: {"type":"text","text":"lo"}
                <- data: {"type":"done","stop_reason":"end_turn"}
         <- parseSse turns each line into TextDelta / StreamDone   lib/core/sse.dart
       each TextDelta appends to the reply bubble -> the screen rebuilds -> text "types out"
```

Look (vision) is the same path with `mode: vision` and an image block in your first message.

## 2. Extract (structured output)

`ExtractController.extract()` calls `ClaudeApi.request(mode: extract)`. The server adds
`output_config.format` with `JOB_POST_SCHEMA` (`supabase/functions/claude/schemas.ts`), which
forces Claude's answer to be JSON in exactly that shape. The app turns it into a `JobPost`.

## 3. Tasks (tool use, the agent loop)

```
AgentController.send("Add milk tomorrow")       lib/features/agent/agent_controller.dart
  round 1: request(mode: agent) -> Claude replies stop_reason "tool_use":
           [tool_use list_tasks {}]                       (Claude wants today's date first)
           ToolExecutor.run("list_tasks") -> {"today": "...", "tasks": []}
           send the result back as a tool_result block
  round 2: Claude replies [tool_use add_task {title: "Milk", due_date: "2026-10-24", ...}]
           ToolExecutor adds the task on the phone
  round 3: Claude replies stop_reason "end_turn": "Added milk for tomorrow."
```

The tools are declared on the server (`AGENT_TOOLS` in `schemas.ts`), so an edited app cannot add
new ones. They run on the phone (`tool_executor.dart`), so the server never sees your task list
except the results the app sends back.

## 4. Sign in

`AuthGate` watches `currentUserProvider`. No user: `AuthScreen`. A user: the tabs.
Sign up and sign in go straight to Supabase Auth (`auth_controller.dart`). Delete account calls the
`delete-account` edge function, which deletes the user and their usage rows.

## 5. Riverpod in one paragraph

A `Notifier` holds a screen's state (like a `ChangeNotifier`). Writing `state = ...` rebuilds every
widget that called `ref.watch(provider)`. Widgets call methods with `ref.read(provider.notifier)`.
That is all this app uses: `NotifierProvider` for state, `Provider` for services, `StreamProvider`
for the signed-in user.

## 6. Files by layer

| Layer | Files |
| --- | --- |
| Start | `main.dart`, `app/home_shell.dart`, `app/theme.dart` |
| Talking to the server | `core/claude_api.dart`, `core/sse.dart`, `core/env.dart`, `core/claude_models.dart` |
| Accounts | `features/auth/*` |
| Chat and Look | `features/conversation/*`, `features/chat/*`, `features/vision/*` |
| Extract | `features/extract/*` |
| Tasks agent | `features/agent/*` |
| Shared widgets | `shared/*` |
| Server | `supabase/functions/claude/*`, `supabase/functions/delete-account/*`, `supabase/migrations/*` |
| Tests | `test/*` (app), `supabase/functions/claude/validate_test.ts` (server) |
