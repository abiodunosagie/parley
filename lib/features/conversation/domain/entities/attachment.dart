// FILE: features/conversation/domain/entities/attachment.dart
// A photo or a PDF attached to the first message of a conversation, with its file type checked
// from the file's first bytes (JPEG, PNG, GIF, WebP or PDF).

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../../core/media/media_type.dart' as media;

/// A photo or PDF on a user message, already in a format Claude accepts.
@immutable
class Attachment {
  const Attachment(this.bytes, this.mediaType, {this.name});
  final Uint8List bytes;
  final String mediaType;

  /// The file name, shown for PDFs and sent as the document title.
  final String? name;

  static const pdf = media.pdfMediaType;

  bool get isPdf => mediaType == pdf;

  /// Reads the file signature, so a HEIC or a renamed file is refused here, not by the server.
  static String? mediaTypeOf(Uint8List bytes) => media.mediaTypeOf(bytes);
}
