// FILE: features/conversation/domain/entities/conversation.dart
// A saved Chat, Look or Read conversation: everything needed to show it again and carry on.

import 'package:meta/meta.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/models/saved_summary.dart';
import 'attachment.dart';
import 'chat_message.dart';
import 'conversation_kind.dart';

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.model,
    required this.messages,
    required this.updatedAt,
    this.attachment,
    this.webSearch = false,
  });

  final String id;
  final ConversationKind kind;

  /// The model the conversation runs on. Claude's reasoning is tied to the model that wrote it,
  /// so a conversation never switches model.
  final ClaudeModel model;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  /// Look's photo or Read's PDF. It rides on the first user message.
  final Attachment? attachment;
  final bool webSearch;

  /// The history title: the first thing you asked, on one line.
  String get title {
    final first = messages.where((m) => m.fromUser).firstOrNull?.text ?? '';
    return oneLineTitle(first);
  }
}
