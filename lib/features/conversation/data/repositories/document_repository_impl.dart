// FILE: features/conversation/data/repositories/document_repository_impl.dart
// The real DocumentRepository, using file_picker. Only PDFs up to 6 MB: every follow-up question
// sends the whole file again, and the server refuses anything larger.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  static const maxBytes = 6 * 1000 * 1000;

  @override
  Future<Attachment?> pick() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } on PlatformException {
      throw const AppException('Parley could not open your files. Try again.');
    }
    if (file == null) return null;
    final size = await file.length();
    if (size != null && size > maxBytes) {
      throw const AppException('That PDF is too large. Pick one under 6 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const AppException('That PDF is too large. Pick one under 6 MB.');
    }
    if (Attachment.mediaTypeOf(bytes) != Attachment.pdf) {
      throw const AppException('That file is not a PDF.');
    }
    return Attachment(bytes, Attachment.pdf, name: file.name);
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(),
);
