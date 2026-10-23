// FILE: features/conversation/presentation/providers/conversation_state.dart
// Everything a Chat, Look or Read screen shows: the messages, whether a reply is streaming, the
// note under the composer, the photo or PDF the conversation is about, the model it is locked to,
// and whether Claude may search the web.

import 'package:flutter/foundation.dart';

import '../../../../core/models/claude_model.dart';
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
    this.id,
    this.messages = const [],
    this.status = ReplyStatus.idle,
    this.notice,
    this.attachment,
    this.model,
    this.webSearch = false,
  });

  /// The saved conversation's id. Null until the first message is sent.
  final String? id;
  final List<ChatMessage> messages;
  final ReplyStatus status;

  /// Why the last reply ended early or failed, shown under the conversation. Null when all is well.
  final String? notice;

  /// Look's photo or Read's PDF. It rides on the first user message.
  final Attachment? attachment;

  /// The model this conversation runs on, fixed at its first message. Claude's reasoning is tied
  /// to the model that wrote it, so switching mid-conversation would break the replay.
  final ClaudeModel? model;

  /// Chat only: Claude may search the web for this conversation.
  final bool webSearch;

  bool get busy => status == ReplyStatus.streaming;
  bool get isEmpty => messages.isEmpty;

  /// A copy with some fields changed. `notice` takes a function so it can be set back to null.
  ConversationState copyWith({
    String? id,
    List<ChatMessage>? messages,
    ReplyStatus? status,
    String? Function()? notice,
    ClaudeModel? model,
    bool? webSearch,
  }) => ConversationState(
    id: id ?? this.id,
    messages: messages ?? this.messages,
    status: status ?? this.status,
    notice: notice == null ? this.notice : notice(),
    attachment: attachment,
    model: model ?? this.model,
    webSearch: webSearch ?? this.webSearch,
  );
}
