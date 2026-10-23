import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/conversation/data/mappers/chat_message_mapper.dart';
import 'package:parley/features/conversation/domain/entities/attachment.dart';
import 'package:parley/features/conversation/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage.toApi (mapper)', () {
    test('plain text stays a string', () {
      expect(const ChatMessage(fromUser: true, text: 'Hi').toApi(), {
        'role': 'user',
        'content': 'Hi',
      });
    });

    test('a photo goes first as a base64 image block, then the question', () {
      final photo = Attachment(Uint8List.fromList([1, 2, 3]), 'image/png');
      final api = ChatMessage(
        fromUser: true,
        text: 'What is this?',
        attachment: photo,
      ).toApi();
      final content = api['content'] as List;
      expect(content[0], {
        'type': 'image',
        'source': {'type': 'base64', 'media_type': 'image/png', 'data': 'AQID'},
      });
      expect(content[1], {'type': 'text', 'text': 'What is this?'});
    });
  });
}
