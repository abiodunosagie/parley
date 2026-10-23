import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/conversation/domain/entities/attachment.dart';

void main() {
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
}
