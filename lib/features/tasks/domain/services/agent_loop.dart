// FILE: features/tasks/domain/services/agent_loop.dart
// FEATURE 4 LOGIC: tool use, the agent loop. The heart of "Claude runs the app":
//   1. Send the conversation to Claude.
//   2. If the reply contains tool_use blocks, run each one with ToolExecutor.
//   3. Send all the results back in one message.
//   4. Repeat until Claude answers in plain text (at most [maxRounds] rounds).
// The transcript only grows by complete steps: a tool round goes in with all its results, and a
// failed or cut-short answer is never added, so there is never a dangling tool_use. Your message
// stays even when the reply fails, exactly like the screen shows it.
// Plain Dart (no Flutter), covered by test/features/tasks/domain/agent_loop_test.dart.

import '../../../../core/errors/user_messages.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/agent_item.dart';
import '../entities/agent_reply.dart';
import '../repositories/agent_repository.dart';
import 'tool_executor.dart';

/// How a run ended: [notice] is what to show under the conversation, or null when all is well.
/// [unexpectedError] is set when something other than a known failure went wrong, for logging.
class AgentRunResult {
  const AgentRunResult({required this.notice, this.unexpectedError});
  final String? notice;
  final Object? unexpectedError;
}

class AgentLoop {
  AgentLoop({
    required this.repository,
    required this.executor,
    this.maxRounds = 8,
  });

  final AgentRepository repository;
  final ToolExecutor executor;
  final int maxRounds;

  /// The conversation as the API sees it. Claude's turns are stored exactly as received.
  final List<Map<String, dynamic>> _transcript = [];

  /// A read-only view of the conversation so far.
  List<Map<String, dynamic>> get transcript => List.unmodifiable(_transcript);

  void clear() => _transcript.clear();

  /// Carries on a saved conversation: [transcript] is what [transcript] returned back then.
  void restore(List<Map<String, dynamic>> transcript) {
    _transcript
      ..clear()
      ..addAll(transcript);
  }

  /// Runs one user message to the end. [onItem] receives each line for the screen as it happens.
  /// [isCurrent] returns false once the screen started over, and the run then stops quietly.
  Future<AgentRunResult> run({
    required String text,
    required ClaudeModel model,
    required CancelToken cancel,
    required void Function(AgentItem item) onItem,
    required bool Function() isCurrent,
  }) async {
    _transcript.add({'role': 'user', 'content': text});
    // The transcript only ever grows by whole steps (your message, a tool round with all its
    // results, a final answer), and the screen shows exactly those steps. So when a run fails
    // halfway, what Claude knows and what you see (and what history saves) stay the same.
    String? notice;
    Object? unexpected;
    var clean = false;
    try {
      for (var round = 0; round < maxRounds && !cancel.isCancelled; round++) {
        final reply = await repository.next(
          model: model,
          transcript: List.of(_transcript),
          cancel: cancel,
        );
        if (!isCurrent()) return const AgentRunResult(notice: null);

        // A tool_use stop with no calls in it is treated as a broken answer, never as a round.
        if (reply.stopReason != 'tool_use' || reply.toolCalls.isEmpty) {
          // Only a non-empty answer with no pending tool call is safe to keep.
          clean = reply.content.isNotEmpty && reply.toolCalls.isEmpty;
          if (clean) {
            _transcript.add({'role': 'assistant', 'content': reply.content});
            _show(reply, onItem);
          }
          notice =
              stopReasonNote(reply.stopReason) ??
              (clean ? null : 'Claude did not finish. Try again.');
          break;
        }

        _show(reply, onItem);
        final results = <Map<String, dynamic>>[];
        for (final call in reply.toolCalls) {
          // Every call gets a result, even after Stop, so the round is always complete.
          final outcome = cancel.isCancelled
              ? const ToolOutcome(
                  content: 'Not run: the user pressed Stop.',
                  summary: 'Skipped after Stop',
                  isError: true,
                )
              : await _runTool(call);
          if (!isCurrent()) return const AgentRunResult(notice: null);
          onItem(ToolRan(outcome.summary, isError: outcome.isError));
          results.add({
            'type': 'tool_result',
            'tool_use_id': call['id'],
            'content': outcome.content,
            if (outcome.isError) 'is_error': true,
          });
        }
        // Claude's turn and every result go in together, in ONE user message for the results,
        // which keeps parallel tool calls working.
        _transcript
          ..add({'role': 'assistant', 'content': reply.content})
          ..add({'role': 'user', 'content': results});
      }
      if (!clean && notice == null) {
        notice = cancel.isCancelled
            ? 'Stopped.'
            : 'Claude used too many steps. Try a simpler request.';
      }
    } catch (e) {
      notice = messageFor(e, cancelled: cancel.isCancelled);
      if (isUnexpected(e, cancelled: cancel.isCancelled)) unexpected = e;
    }
    // A tool that crashed was answered as an error so the round stayed whole; still log it.
    unexpected ??= _toolError;
    _toolError = null;
    return AgentRunResult(notice: notice, unexpectedError: unexpected);
  }

  /// The first tool crash in the current run, handed to the caller for logging.
  Object? _toolError;

  void _show(AgentReply reply, void Function(AgentItem item) onItem) {
    for (final thought in reply.thoughts) {
      onItem(ClaudeThought(thought));
    }
    for (final said in reply.texts) {
      onItem(ClaudeSaid(said));
    }
  }

  Future<ToolOutcome> _runTool(Map<String, dynamic> call) async {
    final input = call['input'];
    try {
      return await executor.run(
        call['name'] as String? ?? '',
        input is Map ? Map<String, dynamic>.from(input) : const {},
      );
    } catch (e) {
      _toolError ??= e;
      return const ToolOutcome(
        content: 'The tool failed on the phone.',
        summary: 'Tool failed',
        isError: true,
      );
    }
  }
}
