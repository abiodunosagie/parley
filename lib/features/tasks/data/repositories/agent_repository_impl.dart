// FILE: features/tasks/data/repositories/agent_repository_impl.dart
// The real AgentRepository. The tools Claude may call are declared on the server (AGENT_TOOLS in
// supabase/functions/claude/schemas.ts), so an edited app cannot add new ones.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../domain/entities/agent_reply.dart';
import '../../domain/repositories/agent_repository.dart';

class AgentRepositoryImpl implements AgentRepository {
  AgentRepositoryImpl(this._client);
  final ClaudeClient _client;

  @override
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  }) async {
    final json = await _client.request(
      mode: ClaudeMode.agent,
      model: model,
      messages: transcript,
      cancel: cancel,
    );
    return AgentReply(
      content: [
        for (final block in json['content'] as List? ?? const [])
          if (block is Map) Map<String, dynamic>.from(block),
      ],
      stopReason: json['stop_reason'] as String?,
    );
  }
}

final agentRepositoryProvider = Provider<AgentRepository>(
  (ref) => AgentRepositoryImpl(ref.watch(claudeClientProvider)),
);
