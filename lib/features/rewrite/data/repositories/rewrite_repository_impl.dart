// FILE: features/rewrite/data/repositories/rewrite_repository_impl.dart
// The real RewriteRepository: streams from the `claude` function in rewrite mode (the server's
// system prompt makes Claude reply with the rewritten text only), and saves finished rewrites on
// the phone under the "rewrites" collection.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../../../core/network/sse.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../core/storage/saved_collection.dart';
import '../../domain/entities/rewrite.dart';
import '../../domain/repositories/rewrite_repository.dart';

class RewriteRepositoryImpl implements RewriteRepository {
  RewriteRepositoryImpl(this._client, LocalStore store)
    : _saved = SavedCollection(store, 'rewrites');
  final ClaudeClient _client;
  final SavedCollection _saved;

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
  Future<List<SavedSummary>> history(String userId) => _saved.history(userId);

  @override
  Future<Rewrite?> load(String userId, String id) =>
      _saved.load(userId, id, (json) async => Rewrite.fromJson(json));

  @override
  Future<void> save(String userId, Rewrite rewrite) => _saved.save(
    userId,
    SavedSummary(
      id: rewrite.id,
      title: rewrite.title,
      subtitle: rewrite.label,
      updatedAt: rewrite.createdAt,
    ),
    rewrite.toJson(),
  );

  @override
  Future<void> delete(String userId, String id) => _saved.delete(userId, id);
}

final rewriteRepositoryProvider = Provider<RewriteRepository>(
  (ref) => RewriteRepositoryImpl(
    ref.watch(claudeClientProvider),
    ref.watch(localStoreProvider),
  ),
);
