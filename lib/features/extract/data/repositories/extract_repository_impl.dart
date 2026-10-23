// FILE: features/extract/data/repositories/extract_repository_impl.dart
// The real ExtractRepository. The server adds the JSON schema (JOB_POST_SCHEMA in
// supabase/functions/claude/schemas.ts), so Claude's answer always has exactly these fields.
// Extracted posts are saved on the phone under the "extract" collection.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../../../core/storage/local_store.dart';
import '../../domain/entities/job_post.dart';
import '../../domain/repositories/extract_repository.dart';

class ExtractRepositoryImpl implements ExtractRepository {
  ExtractRepositoryImpl(this._client, this._store);
  final ClaudeClient _client;
  final LocalStore _store;

  static const _collection = 'extract';

  @override
  Future<ExtractResult> extractJobPost({
    required String text,
    required ClaudeModel model,
    CancelToken? cancel,
  }) async {
    final json = await _client.request(
      mode: ClaudeMode.extract,
      model: model,
      messages: [
        {
          'role': 'user',
          'content': 'Extract the job post fields from this text:\n\n$text',
        },
      ],
      cancel: cancel,
    );
    final fields = json['fields'];
    return fields is Map<String, dynamic>
        ? Extracted(JobPost.fromJson(fields))
        : NotExtracted(json['stop_reason'] as String?);
  }

  @override
  Future<List<SavedSummary>> history(String userId) =>
      _store.list(userId, _collection);

  @override
  Future<SavedJob?> load(String userId, String id) async {
    final json = await _store.read(userId, _collection, id);
    if (json == null) return null;
    try {
      return (
        id: id,
        input: json['input'] as String,
        job: JobPost.fromJson(json['job'] as Map<String, dynamic>),
        savedAt: DateTime.parse(json['saved_at'] as String),
      );
    } catch (e) {
      debugPrint('Parley: saved job post unreadable ($e)');
      return null;
    }
  }

  @override
  Future<void> save(String userId, SavedJob saved) => _store.write(
    userId,
    _collection,
    SavedSummary(
      id: saved.id,
      title: saved.job.title.isEmpty ? 'Job post' : saved.job.title,
      subtitle: saved.job.company,
      updatedAt: saved.savedAt,
    ),
    {
      'version': 1,
      'input': saved.input,
      'job': saved.job.toJson(),
      'saved_at': saved.savedAt.toIso8601String(),
    },
  );

  @override
  Future<void> delete(String userId, String id) =>
      _store.delete(userId, _collection, id);
}

final extractRepositoryProvider = Provider<ExtractRepository>(
  (ref) => ExtractRepositoryImpl(
    ref.watch(claudeClientProvider),
    ref.watch(localStoreProvider),
  ),
);
