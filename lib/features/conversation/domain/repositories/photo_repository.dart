// FILE: features/conversation/domain/repositories/photo_repository.dart
// Gets a photo from the camera or the library, already resized and checked for a supported type.
// Implemented in data/repositories/photo_repository_impl.dart.

import '../entities/attachment.dart';

enum PhotoSource { camera, library }

abstract interface class PhotoRepository {
  /// The chosen photo, or null when the user cancelled. Throws AppException when access is
  /// denied or the file type is not supported.
  Future<Attachment?> pick(PhotoSource source);
}
