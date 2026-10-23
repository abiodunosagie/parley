import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/network/sse.dart';

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
}
