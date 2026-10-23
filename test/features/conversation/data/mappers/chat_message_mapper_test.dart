import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/features/conversation/data/mappers/chat_message_mapper.dart';
import 'package:parley/features/conversation/data/mappers/conversation_json.dart';
import 'package:parley/features/conversation/domain/entities/attachment.dart';
import 'package:parley/features/conversation/domain/entities/chat_message.dart';
import 'package:parley/features/conversation/domain/entities/conversation.dart';
import 'package:parley/features/conversation/domain/entities/conversation_kind.dart';
import 'package:parley/features/conversation/domain/entities/source.dart';

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

  group('replay and documents', () {
    test("Claude's reply goes back exactly as the API returned it", () {
      const turn = [
        {'type': 'thinking', 'thinking': 'x', 'signature': 'sig'},
        {'type': 'text', 'text': 'Hi'},
      ];
      expect(
        const ChatMessage(fromUser: false, text: 'Hi', replay: turn).toApi(),
        {'role': 'assistant', 'content': turn},
      );
    });

    test('a stopped reply without a record goes back as its text', () {
      expect(const ChatMessage(fromUser: false, text: 'Half').toApi(), {
        'role': 'assistant',
        'content': 'Half',
      });
    });

    test('a PDF goes first as a document block named after the file', () {
      final pdf = Attachment(
        Uint8List.fromList([1, 2, 3]),
        Attachment.pdf,
        name: 'a.pdf',
      );
      final content =
          ChatMessage(
                fromUser: true,
                text: 'Sum up',
                attachment: pdf,
              ).toApi()['content']
              as List;
      expect(content[0]['type'], 'document');
      expect(content[0]['title'], 'a.pdf');
      expect(content[0]['source']['media_type'], 'application/pdf');
    });

    test('a saved conversation reads back the same, with the file on its first message', () {
      final pdf = Attachment(
        Uint8List.fromList([1, 2, 3]),
        Attachment.pdf,
        name: 'a.pdf',
      );
      final saved = Conversation(
        id: 'c1',
        kind: ConversationKind.document,
        model: ClaudeModel.sonnet,
        updatedAt: DateTime.utc(2026, 10, 23),
        attachment: pdf,
        messages: [
          ChatMessage(fromUser: true, text: 'Sum up', attachment: pdf),
          const ChatMessage(
            fromUser: false,
            text: 'It says...',
            thinking: 'Reading',
            sources: [
              Source.page(
                title: 'a.pdf',
                startPage: 2,
                endPage: 2,
                citedText: 'q',
              ),
            ],
            replay: [
              {'type': 'text', 'text': 'It says...'},
            ],
          ),
        ],
      );
      final again = conversationFromJson(
        conversationToJson(saved),
        attachment: pdf,
      );
      expect(again.kind, ConversationKind.document);
      expect(again.model, ClaudeModel.sonnet);
      expect(again.messages.first.attachment, same(pdf));
      expect(again.messages.last.attachment, isNull);
      expect(again.messages.last.sources.single.pages, 'Page 2');
      expect(again.messages.last.replay.single['text'], 'It says...');
      expect(again.title, 'Sum up');
    });
  });
}
