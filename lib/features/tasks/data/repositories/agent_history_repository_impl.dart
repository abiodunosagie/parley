// FILE: features/tasks/data/repositories/agent_history_repository_impl.dart
// The real AgentHistoryRepository, on the phone's own storage
// (core/storage/saved_collection.dart), under the "tasks" collection.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../core/storage/saved_collection.dart';
import '../../domain/entities/agent_item.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/repositories/agent_history_repository.dart';

class AgentHistoryRepositoryImpl implements AgentHistoryRepository {
  AgentHistoryRepositoryImpl(LocalStore store)
    : _saved = SavedCollection(store, 'tasks');
  final SavedCollection _saved;

  @override
  Future<List<SavedSummary>> history(String userId) => _saved.history(userId);

  @override
  Future<AgentSession?> load(String userId, String id) => _saved.load(
    userId,
    id,
    (json) async {
      final model = ClaudeModel.values.firstWhere((m) => m.id == json['model']);
      return AgentSession(
        id: json['id'] as String,
        model: model,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        items: [
          for (final item in (json['items'] as List).whereType<Map>())
            ?AgentItem.fromJson(Map<String, dynamic>.from(item)),
        ],
        transcript: [
          for (final turn in (json['transcript'] as List).whereType<Map>())
            Map<String, dynamic>.from(turn),
        ],
      );
    },
  );

  @override
  Future<void> save(String userId, AgentSession session) {
    final steps = session.items.whereType<ToolRan>().length;
    return _saved.save(
      userId,
      SavedSummary(
        id: session.id,
        title: session.title,
        subtitle:
            '$steps ${steps == 1 ? 'tool call' : 'tool calls'} · ${session.model.label}',
        updatedAt: session.updatedAt,
      ),
      {
        'version': 1,
        'id': session.id,
        'model': session.model.id,
        'updated_at': session.updatedAt.toIso8601String(),
        'items': [for (final item in session.items) item.toJson()],
        'transcript': session.transcript,
      },
    );
  }

  @override
  Future<void> delete(String userId, String id) => _saved.delete(userId, id);
}

final agentHistoryRepositoryProvider = Provider<AgentHistoryRepository>(
  (ref) => AgentHistoryRepositoryImpl(ref.watch(localStoreProvider)),
);
