// FILE: features/tasks/domain/repositories/agent_history_repository.dart
// Saved Tasks conversations for one account, kept on the phone so you can go back to them.
// Implemented in data/repositories/agent_history_repository_impl.dart.

import '../../../../core/models/saved_summary.dart';
import '../entities/agent_session.dart';

abstract interface class AgentHistoryRepository {
  Future<List<SavedSummary>> list(String userId);

  /// Null when it was deleted or cannot be read.
  Future<AgentSession?> load(String userId, String id);

  Future<void> save(String userId, AgentSession session);

  Future<void> delete(String userId, String id);
}
