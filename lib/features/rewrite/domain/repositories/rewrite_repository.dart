// FILE: features/rewrite/domain/repositories/rewrite_repository.dart
// Asks Claude to rewrite text (streamed as it is written), and keeps your finished rewrites.
// Implemented in data/repositories/rewrite_repository_impl.dart.

import '../../../../core/models/claude_model.dart';
import '../../../../core/models/saved_summary.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/rewrite.dart';

/// What arrives while Claude rewrites: pieces of text, then how it ended.
sealed class RewriteEvent {
  const RewriteEvent();
}

class RewriteText extends RewriteEvent {
  const RewriteText(this.text);
  final String text;
}

class RewriteDone extends RewriteEvent {
  const RewriteDone(this.stopReason);
  final String? stopReason;
}

class RewriteFailed extends RewriteEvent {
  const RewriteFailed(this.message);
  final String message;
}

abstract interface class RewriteRepository {
  /// Streams the rewrite of [text] following [instruction]. Cancelling [cancel] ends the stream
  /// quietly. Throws AppException when the request fails.
  Stream<RewriteEvent> rewrite({
    required String text,
    required String instruction,
    required ClaudeModel model,
    CancelToken? cancel,
  });

  Future<List<SavedSummary>> history(String userId);
  Future<Rewrite?> load(String userId, String id);
  Future<void> save(String userId, Rewrite rewrite);
  Future<void> delete(String userId, String id);
}
