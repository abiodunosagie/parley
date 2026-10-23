// FILE: features/conversation/data/mappers/chat_message_mapper.dart
// Turns a ChatMessage into the Messages API shape the server expects. Your messages: plain text,
// or an image or document block (base64) followed by the question. Claude's replies: the turn
// exactly as the API returned it, so reasoning and searches carry on; a stopped reply that has
// no such record goes back as its text.

import 'dart:convert';

import '../../domain/entities/chat_message.dart';

extension ChatMessageApi on ChatMessage {
  Map<String, dynamic> toApi() {
    if (!fromUser) {
      return {
        'role': 'assistant',
        'content': replay.isNotEmpty ? replay : text,
      };
    }
    final file = attachment;
    if (file == null) return {'role': 'user', 'content': text};
    final source = {
      'type': 'base64',
      'media_type': file.mediaType,
      'data': base64Encode(file.bytes),
    };
    return {
      'role': 'user',
      'content': [
        file.isPdf
            ? {'type': 'document', 'source': source, 'title': ?file.name}
            : {'type': 'image', 'source': source},
        {'type': 'text', 'text': text},
      ],
    };
  }
}
