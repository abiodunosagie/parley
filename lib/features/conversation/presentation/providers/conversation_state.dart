// FILE: features/conversation/presentation/providers/conversation_state.dart
// Everything a Chat or Look screen shows: the messages, whether a reply is streaming, the note
// under the composer, and (Look only) the photo the conversation is about.

import 'package:flutter/foundation.dart';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/chat_message.dart';

enum ReplyStatus {
  /// Waiting for the user.
  idle,

  /// Claude is writing; the composer shows Stop.
  streaming,
}

@immutable
class ConversationState {
  const ConversationState({
    this.messages = const [],
    this.status = ReplyStatus.idle,
    this.notice,
    this.photo,
  });

  final List<ChatMessage> messages;
  final ReplyStatus status;

  /// Why the last reply ended early or failed, shown under the conversation. Null when all is well.
  final String? notice;

  /// Look only: the photo the conversation is about. It rides on the first user message.
  final Attachment? photo;

  bool get busy => status == ReplyStatus.streaming;
  bool get isEmpty => messages.isEmpty;
}
