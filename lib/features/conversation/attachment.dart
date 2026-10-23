import 'package:flutter/foundation.dart';

/// A photo attached to a user message, already in a format Claude accepts.
@immutable
class Attachment {
  const Attachment(this.bytes, this.mediaType);
  final Uint8List bytes;
  final String mediaType;

  /// Reads the file signature, so a HEIC or a renamed file is refused here, not by the server.
  static String? mediaTypeOf(Uint8List b) {
    bool starts(List<int> sig, [int offset = 0]) =>
        b.length >= offset + sig.length && listEquals(b.sublist(offset, offset + sig.length), sig);
    if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (starts([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) return 'image/webp';
    return null;
  }
}
