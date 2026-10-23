// FILE: features/agent/agent_controller.dart
// FEATURE 4 LOGIC: tool use, the agent loop. The heart of "Claude runs the app":
//   1. Send the conversation to Claude (mode "agent").
//   2. If the reply contains tool_use blocks, run each one with ToolExecutor.
//   3. Send all results back in one message.
//   4. Repeat until Claude answers in plain text (at most 8 rounds).
// If anything fails, the conversation is rolled back to before your message so it stays valid.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/claude_api.dart';
import '../../core/claude_models.dart';
import 'reminders.dart';
import 'task_store.dart';
import 'tool_executor.dart';

/// One line in the agent transcript on screen.
sealed class AgentItem {
  const AgentItem();
}

class UserSaid extends AgentItem {
  const UserSaid(this.text);
  final String text;
}

class ClaudeSaid extends AgentItem {
  const ClaudeSaid(this.text);
  final String text;
}

class ToolRan extends AgentItem {
  const ToolRan(this.summary, {required this.isError});
  final String summary;
  final bool isError;
}

@immutable
class AgentState {
  const AgentState({
    this.items = const [],
    this.busy = false,
    this.notice,
    this.model,
  });
  final List<AgentItem> items;
  final bool busy;
  final String? notice;

  /// The model this conversation runs on, fixed at its first message. Claude's thinking blocks
  /// are tied to the model that wrote them, so switching mid-conversation would break the replay.
  final ClaudeModel? model;
}

/// Feature 4: tool use, the agent loop.
///
/// 1. Send the conversation. 2. If Claude answers with tool_use blocks, run them on the phone.
/// 3. Send every result back in one user message. 4. Repeat until Claude ends its turn.
/// Claude's turns go back exactly as received (thinking blocks included); the API needs them
/// unchanged to keep its reasoning valid across tool calls.
class AgentController extends Notifier<AgentState> {
  static const _maxRounds = 8;

  final List<Map<String, dynamic>> _transcript = [];

  /// The send that owns the state; see ConversationController for the same pattern.
  CancelToken? _current;

  @override
  AgentState build() {
    // Signing out disposes this controller: stop the running request so it stops spending.
    ref.onDispose(() => _current?.cancel());
    return const AgentState();
  }

  void stop() => _current?.cancel();

  void reset() {
    _current?.cancel();
    _current = null;
    _transcript.clear();
    state = const AgentState();
  }

  Future<void> send(String text) async {
    if (state.busy) return;
    final token = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, token);
    final ClaudeModel model = state.model ?? ref.read(selectedModelProvider);
    final switched = model != ref.read(selectedModelProvider);

    // A failed or cut-short turn is rolled back to here, so the transcript always ends on a clean
    // assistant reply: a dangling tool_use or an empty turn would make every later send fail.
    final rollbackTo = _transcript.length;
    _transcript.add({'role': 'user', 'content': text});
    state = AgentState(
      items: [...state.items, UserSaid(text)],
      busy: true,
      model: model,
    );

    final executor = ToolExecutor(_PhoneActions(ref));
    String? notice;
    var clean = false;
    try {
      for (var round = 0; round < _maxRounds && !token.isCancelled; round++) {
        final outcome = await _round(model, executor, token, stillMine);
        if (outcome == null) return; // A newer send or a reset took over.
        if (outcome.finished) {
          clean = outcome.clean;
          notice = outcome.notice;
          break;
        }
      }
      if (!clean && notice == null) {
        notice = token.isCancelled
            ? 'Stopped.'
            : 'Claude used too many steps. Try a simpler request.';
      }
    } catch (e) {
      notice = noticeFor(e, cancelled: token.isCancelled, tag: 'agent');
    }

    if (!stillMine()) return;
    _current = null;
    if (!clean) _transcript.removeRange(rollbackTo, _transcript.length);
    if (switched && notice == null) {
      notice =
          'This conversation stays on ${model.label}. Start a new one to use another model.';
    }
    state = AgentState(items: state.items, notice: notice, model: model);
  }

  /// One request to Claude, plus running any tools it asked for. Null when this send was replaced.
  Future<({bool finished, bool clean, String? notice})?> _round(
    ClaudeModel model,
    ToolExecutor executor,
    CancelToken token,
    bool Function() stillMine,
  ) async {
    final reply = await ref
        .read(claudeApiProvider)
        .request(
          mode: ClaudeMode.agent,
          model: model,
          messages: List.of(_transcript),
          cancel: token,
        );
    if (!stillMine()) return null;

    final content = [
      for (final b in reply['content'] as List? ?? const [])
        if (b is Map) Map<String, dynamic>.from(b),
    ];
    final stopReason = reply['stop_reason'] as String?;
    final toolCalls = [
      for (final b in content)
        if (b['type'] == 'tool_use') b,
    ];

    for (final block in content) {
      final said = block['type'] == 'text'
          ? (block['text'] as String? ?? '').trim()
          : '';
      if (said.isNotEmpty) _show(ClaudeSaid(said));
    }

    if (stopReason != 'tool_use') {
      // Only a non-empty answer with no pending tool call is safe to keep in the transcript.
      final clean = content.isNotEmpty && toolCalls.isEmpty;
      if (clean) _transcript.add({'role': 'assistant', 'content': content});
      return (
        finished: true,
        clean: clean,
        notice:
            stopReasonNote(stopReason) ??
            (clean ? null : 'Claude did not finish. Try again.'),
      );
    }

    _transcript.add({'role': 'assistant', 'content': content});
    final results = <Map<String, dynamic>>[];
    for (final call in toolCalls) {
      final input = call['input'];
      final outcome = await executor.run(
        call['name'] as String? ?? '',
        input is Map ? Map<String, dynamic>.from(input) : const {},
      );
      if (!stillMine()) return null;
      _show(ToolRan(outcome.summary, isError: outcome.isError));
      results.add({
        'type': 'tool_result',
        'tool_use_id': call['id'],
        'content': outcome.content,
        if (outcome.isError) 'is_error': true,
      });
    }
    _transcript.add({'role': 'user', 'content': results});
    return (finished: false, clean: false, notice: null);
  }

  void _show(AgentItem item) => state = AgentState(
    items: [...state.items, item],
    busy: true,
    model: state.model,
  );
}

/// The real phone: tasks in SharedPreferences, reminders as local notifications.
class _PhoneActions implements ToolActions {
  _PhoneActions(this.ref);
  final Ref ref;

  TaskStore get _store => ref.read(taskStoreProvider.notifier);

  @override
  Future<List<Task>> tasks() => _store.current();

  @override
  Future<Task> addTask({
    required String title,
    required String dueDate,
    required String priority,
  }) => _store.add(title: title, dueDate: dueDate, priority: priority);

  @override
  Future<Task?> completeTask(String id) => _store.setDone(id);

  @override
  Future<bool> scheduleReminder({
    required String text,
    required int minutesFromNow,
  }) => ref
      .read(remindersProvider)
      .schedule(text: text, minutesFromNow: minutesFromNow);

  @override
  DateTime now() => DateTime.now();
}

final agentProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);
