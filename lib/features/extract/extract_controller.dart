import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/claude_api.dart';
import '../../core/claude_models.dart';
import 'job_post.dart';

@immutable
class ExtractState {
  const ExtractState({this.busy = false, this.result, this.notice});
  final bool busy;
  final JobPost? result;
  final String? notice;
}

/// Feature 3: structured output. One request, one JSON object back, no streaming needed.
class ExtractController extends Notifier<ExtractState> {
  CancelToken? _cancel;

  @override
  ExtractState build() => const ExtractState();

  void cancel() => _cancel?.cancel();

  Future<void> extract(String text) async {
    final input = text.trim();
    if (input.isEmpty || state.busy) return;
    state = const ExtractState(busy: true);
    final cancel = _cancel = CancelToken();
    try {
      final json = await ref.read(claudeApiProvider).request(
            mode: ClaudeMode.extract,
            model: ref.read(selectedModelProvider),
            messages: [
              {'role': 'user', 'content': 'Extract the job post fields from this text:\n\n$input'},
            ],
            cancel: cancel,
          );
      if (!ref.mounted) return;
      final fields = json['fields'];
      state = fields is Map<String, dynamic>
          ? ExtractState(result: JobPost.fromJson(fields))
          : ExtractState(notice: stopReasonNote(json['stop_reason'] as String?) ?? 'No fields came back. Try again.');
    } catch (e) {
      if (ref.mounted) state = ExtractState(notice: noticeFor(e, cancelled: cancel.isCancelled, tag: 'extract'));
    }
  }
}

final extractProvider = NotifierProvider<ExtractController, ExtractState>(ExtractController.new);
