// FILE: features/conversation/data/mappers/chat_message_mapper.dart
// Turns a ChatMessage into the Messages API shape the server expects: plain text, or an image
// block (base64) followed by the question.

import 'dart:convert';

import '../../domain/entities/chat_message.dart';

extension ChatMessageApi on ChatMessage {
  Map<String, dynamic> toApi() {
    final role = fromUser ? 'user' : 'assistant';
    final image = attachment;
    if (image == null) return {'role': role, 'content': text};
    return {
      'role': role,
      'content': [
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': image.mediaType,
            'data': base64Encode(image.bytes),
          },
        },
        {'type': 'text', 'text': text},
      ],
    };
  }
}
