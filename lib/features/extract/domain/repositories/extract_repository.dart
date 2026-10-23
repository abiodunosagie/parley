// FILE: features/extract/domain/repositories/extract_repository.dart
// Turns pasted text into a JobPost with structured output, and keeps the posts you extracted.
// Implemented in data/repositories/extract_repository_impl.dart.

import '../../../../core/models/claude_model.dart';
import '../../../../core/models/saved_summary.dart';
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

/// A job post you extracted, as saved in history.
typedef SavedJob = ({String id, String input, JobPost job, DateTime savedAt});

abstract interface class ExtractRepository {
  /// Throws AppException when the request fails.
  Future<ExtractResult> extractJobPost({
    required String text,
    required ClaudeModel model,
    CancelToken? cancel,
  });

  Future<List<SavedSummary>> history(String userId);
  Future<SavedJob?> load(String userId, String id);
  Future<void> save(String userId, SavedJob saved);
  Future<void> delete(String userId, String id);
}
