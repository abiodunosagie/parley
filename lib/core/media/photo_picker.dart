// FILE: core/media/photo_picker.dart
// Takes or picks a photo with image_picker, resized to 1568 px on the long edge (the largest size
// Claude uses without shrinking it again) and saved as JPEG at 85% quality. Shared by Look and
// Receipts through their own repositories.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_exception.dart';
import 'media_type.dart';
import 'photo_source.dart';

export 'photo_source.dart';

typedef PickedPhoto = ({Uint8List bytes, String mediaType});

class PhotoPicker {
  PhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  static const _maxEdge = 1568.0;
  static const _jpegQuality = 85;

  /// The chosen photo, or null when you cancelled. Throws AppException when access is denied or
  /// the file type is not supported.
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
        imageQuality: _jpegQuality,
      );
    } on PlatformException {
      throw const AppException(
        'Parley needs camera or photo access. Turn it on in Settings.',
      );
    }
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final type = mediaTypeOf(bytes);
    if (type == null || type == pdfMediaType) {
      throw const AppException(
        'That file type is not supported. Use a JPEG, PNG, WebP or GIF image.',
      );
    }
    return (bytes: bytes, mediaType: type);
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => PhotoPicker());
