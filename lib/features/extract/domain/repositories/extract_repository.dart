// FILE: features/extract/domain/repositories/extract_repository.dart
// Turns pasted text into a JobPost with structured output. Implemented in
// data/repositories/extract_repository_impl.dart.

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/job_post.dart';

sealed class ExtractResult {
  const ExtractResult();
}

class Extracted extends ExtractResult {
  const Extracted(this.job);
  final JobPost job;
}

/// Claude answered without fields (for example it declined, or hit its length limit).
class NotExtracted extends ExtractResult {
  const NotExtracted(this.stopReason);
  final String? stopReason;
}

abstract interface class ExtractRepository {
  /// Throws AppException when the request fails.
  Future<ExtractResult> extractJobPost({
    required String text,
    required ClaudeModel model,
    CancelToken? cancel,
  });
}
