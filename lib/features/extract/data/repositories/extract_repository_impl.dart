// FILE: features/extract/data/repositories/extract_repository_impl.dart
// The real ExtractRepository. The server adds the JSON schema (JOB_POST_SCHEMA in
// supabase/functions/claude/schemas.ts), so Claude's answer always has exactly these fields.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../domain/entities/job_post.dart';
import '../../domain/repositories/extract_repository.dart';

class ExtractRepositoryImpl implements ExtractRepository {
  ExtractRepositoryImpl(this._client);
  final ClaudeClient _client;

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
}

final extractRepositoryProvider = Provider<ExtractRepository>(
  (ref) => ExtractRepositoryImpl(ref.watch(claudeClientProvider)),
);
