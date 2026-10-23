// FILE: features/conversation/domain/repositories/conversation_history_repository.dart
// Saved conversations for one account, kept on the phone so you can go back to them.
// Implemented in data/repositories/conversation_history_repository_impl.dart.

import '../../../../core/models/saved_summary.dart';
import '../entities/conversation.dart';
import '../entities/conversation_kind.dart';

abstract interface class ConversationHistoryRepository {
  /// One feature's saved conversations, newest first.
  Future<List<SavedSummary>> history(String userId, ConversationKind kind);

  /// Null when it was deleted or cannot be read.
  Future<Conversation?> load(String userId, ConversationKind kind, String id);

  Future<void> save(String userId, Conversation conversation);

  Future<void> delete(String userId, ConversationKind kind, String id);
}
