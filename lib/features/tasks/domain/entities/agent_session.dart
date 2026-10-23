// FILE: features/tasks/domain/entities/agent_session.dart
// A saved Tasks conversation: the lines on screen, the transcript Claude needs to carry on, and
// the model it is locked to.

import 'package:meta/meta.dart';

import '../../../../core/models/claude_model.dart';
import 'agent_item.dart';

@immutable
class AgentSession {
  const AgentSession({
    required this.id,
    required this.model,
    required this.items,
    required this.transcript,
    required this.updatedAt,
  });

  final String id;
  final ClaudeModel model;
  final List<AgentItem> items;

  /// The conversation as the API sees it, Claude's turns exactly as received.
  final List<Map<String, dynamic>> transcript;
  final DateTime updatedAt;

  /// The history title: the first thing you asked, on one line.
  String get title {
    final first = items.whereType<UserSaid>().firstOrNull?.text ?? '';
    final line = first.replaceAll(RegExp(r'\s+'), ' ').trim();
    return line.length <= 60 ? line : '${line.substring(0, 57)}...';
  }
}
