// FILE: features/conversation/data/repositories/photo_repository_impl.dart
// The real PhotoRepository, using image_picker. Photos are resized to 1568 px on the long edge,
// the largest size Claude uses without shrinking it again, and saved as JPEG at 85% quality.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  static const _maxEdge = 1568.0;
  static const _jpegQuality = 85;

  @override
  Future<Attachment?> pick(PhotoSource source) async {
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
    final type = Attachment.mediaTypeOf(bytes);
    if (type == null) {
      throw const AppException(
        'That file type is not supported. Use a JPEG, PNG, WebP or GIF image.',
      );
    }
    return Attachment(bytes, type);
  }
}

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepositoryImpl(),
);
