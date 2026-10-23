// FILE: features/tasks/domain/entities/agent_reply.dart
// One turn from Claude in the agent loop. [content] is Claude's content blocks exactly as the API
// returned them (text, tool_use, thinking). They go back to the API unchanged, so they stay as
// raw maps instead of being converted to Dart objects and back.

class AgentReply {
  const AgentReply({required this.content, required this.stopReason});
  final List<Map<String, dynamic>> content;
  final String? stopReason;

  List<Map<String, dynamic>> get toolCalls => [
    for (final block in content)
      if (block['type'] == 'tool_use') block,
  ];

  /// Claude's summarized reasoning for this turn, one entry per thinking block.
  Iterable<String> get thoughts sync* {
    for (final block in content) {
      final text = block['type'] == 'thinking'
          ? (block['thinking'] as String? ?? '').trim()
          : '';
      if (text.isNotEmpty) yield text;
    }
  }

  Iterable<String> get texts sync* {
    for (final block in content) {
      final text = block['type'] == 'text'
          ? (block['text'] as String? ?? '').trim()
          : '';
      if (text.isNotEmpty) yield text;
    }
  }
}
