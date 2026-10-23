import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/sse.dart';
import 'package:parley/features/conversation/attachment.dart';
import 'package:parley/features/conversation/conversation.dart';
import 'package:parley/features/extract/job_post.dart';

Stream<List<int>> _wire(List<String> chunks) =>
    Stream.fromIterable([for (final c in chunks) utf8.encode(c)]);

void main() {
  group('parseSse', () {
    test('reads text deltas and the done event', () async {
      final events = await parseSse(
        _wire([
          'data: {"type":"text","text":"Hel"}\n\n',
          'data: {"type":"text","text":"lo"}\n\n',
          'data: {"type":"done","stop_reason":"end_turn","usage":{"input_tokens":5,"output_tokens":2},"model":"claude-opus-5-5"}\n\n',
        ]),
      ).toList();
      expect(events, hasLength(3));
      expect((events[0] as TextDelta).text, 'Hel');
      expect((events[1] as TextDelta).text, 'lo');
      expect((events[2] as StreamDone).stopReason, 'end_turn');
    });

    test('joins an event split across network chunks', () async {
      final events = await parseSse(
        _wire(['data: {"type":"te', 'xt","text":"ok"}\n', '\n']),
      ).toList();
      expect((events.single as TextDelta).text, 'ok');
    });

    test(
      'turns server errors into StreamFailed and skips unknown events',
      () async {
        final events = await parseSse(
          _wire([
            'data: {"type":"ping"}\n\n',
            'data: {"type":"error","message":"Claude is busy right now."}\n\n',
          ]),
        ).toList();
        expect(
          (events.single as StreamFailed).message,
          'Claude is busy right now.',
        );
      },
    );

    test('keeps multi-byte characters intact across chunks', () async {
      final bytes = utf8.encode('data: {"type":"text","text":"naïve ✓"}\n\n');
      final split = Stream.fromIterable([
        bytes.sublist(0, 30),
        bytes.sublist(30),
      ]);
      final events = await parseSse(split).toList();
      expect((events.single as TextDelta).text, 'naïve ✓');
    });
  });

  group('Attachment.mediaTypeOf', () {
    test('recognises the four formats Claude accepts', () {
      expect(
        Attachment.mediaTypeOf(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        Attachment.mediaTypeOf(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D]),
        ),
        'image/png',
      );
      expect(
        Attachment.mediaTypeOf(Uint8List.fromList(ascii.encode('GIF89a'))),
        'image/gif',
      );
      expect(
        Attachment.mediaTypeOf(
          Uint8List.fromList(ascii.encode('RIFF\x00\x00\x00\x00WEBPVP8 ')),
        ),
        'image/webp',
      );
    });

    test('refuses HEIC, short and empty files', () {
      expect(
        Attachment.mediaTypeOf(
          Uint8List.fromList(ascii.encode('\x00\x00\x00\x18ftypheic')),
        ),
        isNull,
      );
      expect(Attachment.mediaTypeOf(Uint8List.fromList([0xFF, 0xD8])), isNull);
      expect(Attachment.mediaTypeOf(Uint8List(0)), isNull);
    });
  });

  group('ChatMessage.toApi', () {
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

  group('JobPost.fromJson', () {
    test('trims values and drops empty list items', () {
      final job = JobPost.fromJson({
        'title': ' Mobile Engineer ',
        'company': 'Brightloop',
        'location': '',
        'remote': 'hybrid',
        'seniority': 'mid',
        'salary': 'EUR 55k to 70k',
        'skills': ['TypeScript', ' ', 'Expo'],
        'nice_to_have': [],
        'summary': 'Own the app.',
        'apply_by': '',
      });
      expect(job.title, 'Mobile Engineer');
      expect(job.skills, ['TypeScript', 'Expo']);
      expect(JobPost.enumLabel(job.workStyle), 'Hybrid');
      expect(JobPost.enumLabel('not_stated'), 'Not stated');
      expect(JobPost.enumLabel('onsite'), 'On site');
    });

    test('missing keys become empty values instead of crashing', () {
      final job = JobPost.fromJson({});
      expect(job.title, '');
      expect(job.skills, isEmpty);
    });
  });
}
