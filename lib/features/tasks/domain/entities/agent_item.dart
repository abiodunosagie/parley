// FILE: features/tasks/domain/entities/agent_item.dart
// One line in the Tasks conversation on screen: what you said, what Claude said, or a tool Claude
// ran (with whether it failed).

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
