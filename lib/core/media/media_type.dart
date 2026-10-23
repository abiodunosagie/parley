// FILE: core/media/media_type.dart
// Tells a file's type from its first bytes (JPEG, PNG, GIF, WebP or PDF), so a HEIC photo or a
// renamed file is refused on the phone, not by the server. Plain Dart.

import 'dart:typed_data';

const pdfMediaType = 'application/pdf';

/// The media type Claude knows the file as, or null when it is not one Claude accepts.
String? mediaTypeOf(Uint8List b) {
  bool starts(List<int> sig, [int offset = 0]) {
    if (b.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (starts([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (starts([0x52, 0x49, 0x46, 0x46]) && starts([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  if (starts([0x25, 0x50, 0x44, 0x46, 0x2D])) return pdfMediaType;
  return null;
}
