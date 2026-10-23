// FILE: features/tasks/domain/services/agent_loop.dart
// FEATURE 4 LOGIC: tool use, the agent loop. The heart of "Claude runs the app":
//   1. Send the conversation to Claude.
//   2. If the reply contains tool_use blocks, run each one with ToolExecutor.
//   3. Send all the results back in one message.
//   4. Repeat until Claude answers in plain text (at most [maxRounds] rounds).
// If a turn fails or is cut short, the transcript is rolled back to before your message, so it
// always ends on a clean assistant reply. A dangling tool_use or an empty turn would make every
// later request fail. Pure Dart: covered by test/features/tasks/domain/agent_loop_test.dart.

import '../../../../core/errors/user_messages.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/agent_item.dart';
import '../repositories/agent_repository.dart';
import 'tool_executor.dart';

/// How a run ended: [notice] is what to show under the conversation, or null when all is well.
class AgentRunResult {
  const AgentRunResult({required this.notice});
  final String? notice;
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
  final List<Map<String, dynamic>> transcript = [];

  void clear() => transcript.clear();

  /// Runs one user message to the end. [onItem] receives each line for the screen as it happens.
  /// [isCurrent] returns false once the screen started over, and the run then stops quietly.
  Future<AgentRunResult> run({
    required String text,
    required ClaudeModel model,
    required CancelToken cancel,
    required void Function(AgentItem item) onItem,
    required bool Function() isCurrent,
  }) async {
    final rollbackTo = transcript.length;
    transcript.add({'role': 'user', 'content': text});
    String? notice;
    var clean = false;
    try {
      for (var round = 0; round < maxRounds && !cancel.isCancelled; round++) {
        final reply = await repository.next(
          model: model,
          transcript: List.of(transcript),
          cancel: cancel,
        );
        if (!isCurrent()) return const AgentRunResult(notice: null);
        for (final said in reply.texts) {
          onItem(ClaudeSaid(said));
        }

        if (reply.stopReason != 'tool_use') {
          // Only a non-empty answer with no pending tool call is safe to keep.
          clean = reply.content.isNotEmpty && reply.toolCalls.isEmpty;
          if (clean) {
            transcript.add({'role': 'assistant', 'content': reply.content});
          }
          notice =
              stopReasonNote(reply.stopReason) ??
              (clean ? null : 'Claude did not finish. Try again.');
          break;
        }

        transcript.add({'role': 'assistant', 'content': reply.content});
        final results = <Map<String, dynamic>>[];
        for (final call in reply.toolCalls) {
          final input = call['input'];
          final outcome = await executor.run(
            call['name'] as String? ?? '',
            input is Map ? Map<String, dynamic>.from(input) : const {},
          );
          if (!isCurrent()) return const AgentRunResult(notice: null);
          onItem(ToolRan(outcome.summary, isError: outcome.isError));
          results.add({
            'type': 'tool_result',
            'tool_use_id': call['id'],
            'content': outcome.content,
            if (outcome.isError) 'is_error': true,
          });
        }
        // Every result goes back in ONE user message, which keeps parallel tool calls working.
        transcript.add({'role': 'user', 'content': results});
      }
      if (!clean && notice == null) {
        notice = cancel.isCancelled
            ? 'Stopped.'
            : 'Claude used too many steps. Try a simpler request.';
      }
    } catch (e) {
      notice = messageFor(e, cancelled: cancel.isCancelled, tag: 'agent');
    }
    if (!clean && isCurrent()) {
      transcript.removeRange(rollbackTo, transcript.length);
    }
    return AgentRunResult(notice: notice);
  }
}
