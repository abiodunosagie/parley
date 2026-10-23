// FILE: features/tasks/data/repositories/agent_history_repository_impl.dart
// The real AgentHistoryRepository, on the phone's own storage (core/storage/local_store.dart),
// under the "tasks" collection.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/storage/local_store.dart';
import '../../domain/entities/agent_item.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/repositories/agent_history_repository.dart';

class AgentHistoryRepositoryImpl implements AgentHistoryRepository {
  AgentHistoryRepositoryImpl(this._store);
  final LocalStore _store;

  static const _collection = 'tasks';

  @override
  Future<List<SavedSummary>> list(String userId) =>
      _store.list(userId, _collection);

  @override
  Future<AgentSession?> load(String userId, String id) async {
    final json = await _store.read(userId, _collection, id);
    if (json == null) return null;
    try {
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
    } catch (e) {
      debugPrint('Parley: saved task conversation unreadable ($e)');
      return null;
    }
  }

  @override
  Future<void> save(String userId, AgentSession session) {
    final steps = session.items.whereType<ToolRan>().length;
    return _store.write(
      userId,
      _collection,
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
  Future<void> delete(String userId, String id) =>
      _store.delete(userId, _collection, id);
}

final agentHistoryRepositoryProvider = Provider<AgentHistoryRepository>(
  (ref) => AgentHistoryRepositoryImpl(ref.watch(localStoreProvider)),
);
