// FILE: features/tasks/domain/repositories/agent_repository.dart
// One round of the agent loop: send the transcript, get Claude's next turn. Implemented in
// data/repositories/agent_repository_impl.dart.

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/agent_reply.dart';

abstract interface class AgentRepository {
  /// Throws AppException when the request fails.
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  });
}
