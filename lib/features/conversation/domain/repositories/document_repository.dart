// FILE: features/conversation/domain/repositories/document_repository.dart
// Lets you pick a PDF from the phone's files, already checked for type and size.
// Implemented in data/repositories/document_repository_impl.dart.

import '../entities/attachment.dart';

abstract interface class DocumentRepository {
  /// The chosen PDF, or null when you cancelled. Throws AppException when the file is not a PDF
  /// or is too large.
  Future<Attachment?> pick();
}
