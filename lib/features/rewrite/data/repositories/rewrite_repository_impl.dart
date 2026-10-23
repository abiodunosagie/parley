// FILE: features/rewrite/data/repositories/rewrite_repository_impl.dart
// The real RewriteRepository: streams from the `claude` function in rewrite mode (the server's
// system prompt makes Claude reply with the rewritten text only), and saves finished rewrites on
// the phone under the "rewrites" collection.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../../../core/network/sse.dart';
import '../../../../core/storage/local_store.dart';
import '../../domain/entities/rewrite.dart';
import '../../domain/repositories/rewrite_repository.dart';

class RewriteRepositoryImpl implements RewriteRepository {
  RewriteRepositoryImpl(this._client, this._store);
  final ClaudeClient _client;
  final LocalStore _store;

  static const _collection = 'rewrites';

  @override
  Stream<RewriteEvent> rewrite({
    required String text,
    required String instruction,
    required ClaudeModel model,
    CancelToken? cancel,
  }) async* {
    final events = _client.stream(
      mode: ClaudeMode.rewrite,
      model: model,
      messages: [
        {'role': 'user', 'content': '$instruction\n\n$text'},
      ],
      cancel: cancel,
    );
    await for (final event in events) {
      switch (event) {
        case TextDelta(:final text):
          yield RewriteText(text);
        case StreamDone(:final stopReason):
          yield RewriteDone(stopReason);
        case StreamFailed(:final message):
          yield RewriteFailed(message);
        case ThinkingDelta() || SearchRan() || SourceCited():
          break;
      }
    }
  }

  @override
  Future<List<SavedSummary>> history(String userId) =>
      _store.list(userId, _collection);

  @override
  Future<Rewrite?> load(String userId, String id) async {
    final json = await _store.read(userId, _collection, id);
    if (json == null) return null;
    try {
      return Rewrite.fromJson(json);
    } catch (e) {
      debugPrint('Parley: saved rewrite unreadable ($e)');
      return null;
    }
  }

  @override
  Future<void> save(String userId, Rewrite rewrite) {
    final line = rewrite.input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _store.write(
      userId,
      _collection,
      SavedSummary(
        id: rewrite.id,
        title: line.length <= 60 ? line : '${line.substring(0, 57)}...',
        subtitle: rewrite.label,
        updatedAt: rewrite.createdAt,
      ),
      rewrite.toJson(),
    );
  }

  @override
  Future<void> delete(String userId, String id) =>
      _store.delete(userId, _collection, id);
}

final rewriteRepositoryProvider = Provider<RewriteRepository>(
  (ref) => RewriteRepositoryImpl(
    ref.watch(claudeClientProvider),
    ref.watch(localStoreProvider),
  ),
);
