// FILE: features/conversation/domain/entities/chat_message.dart
// One turn in a Chat or Look conversation: who said it, the text, and an optional photo.
// How it is sent to the server lives in data/mappers/chat_message_mapper.dart.

import 'package:flutter/foundation.dart';

import 'attachment.dart';

@immutable
class ChatMessage {
  const ChatMessage({
    required this.fromUser,
    required this.text,
    this.attachment,
  });
  final bool fromUser;
  final String text;
  final Attachment? attachment;

  ChatMessage withText(String value) =>
      ChatMessage(fromUser: fromUser, text: value, attachment: attachment);
}
