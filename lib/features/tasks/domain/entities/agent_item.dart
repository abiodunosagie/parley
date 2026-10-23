// FILE: features/tasks/domain/entities/agent_item.dart
// One line in the Tasks conversation on screen: what you said, how Claude reasoned, what Claude
// said, or a tool Claude ran (with whether it failed). Saved with the conversation, so each kind
// knows how to turn itself into JSON and back.

sealed class AgentItem {
  const AgentItem();

  Map<String, dynamic> toJson() => switch (this) {
    UserSaid(:final text) => {'kind': 'user', 'text': text},
    ClaudeThought(:final text) => {'kind': 'thought', 'text': text},
    ClaudeSaid(:final text) => {'kind': 'claude', 'text': text},
    ToolRan(:final summary, :final isError) => {
      'kind': 'tool',
      'text': summary,
      'is_error': isError,
    },
  };

  /// Null for anything this app version does not know.
  static AgentItem? fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String) return null;
    return switch (json['kind']) {
      'user' => UserSaid(text),
      'thought' => ClaudeThought(text),
      'claude' => ClaudeSaid(text),
      'tool' => ToolRan(text, isError: json['is_error'] == true),
      _ => null,
    };
  }
}

class UserSaid extends AgentItem {
  const UserSaid(this.text);
  final String text;
}

/// Claude's summarized reasoning before it acted or answered.
class ClaudeThought extends AgentItem {
  const ClaudeThought(this.text);
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
