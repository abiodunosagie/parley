// FILE: features/conversation/data/repositories/photo_repository_impl.dart
// The real PhotoRepository: the shared photo picker (core/media/photo_picker.dart), with the
// photo wrapped as a message attachment.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/photo_picker.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl(this._picker);
  final PhotoPicker _picker;

  @override
  Future<Attachment?> pick(PhotoSource source) async {
    final photo = await _picker.pick(source);
    return photo == null ? null : Attachment(photo.bytes, photo.mediaType);
  }
}

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepositoryImpl(ref.watch(photoPickerProvider)),
);
