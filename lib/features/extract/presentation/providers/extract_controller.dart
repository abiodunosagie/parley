// FILE: features/extract/presentation/providers/extract_controller.dart
// FEATURE 3 LOGIC: structured output. One request, one JSON object back, turned into a JobPost.
// The screen shows one of four explicit states: idle, extracting, done, or failed.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../data/repositories/extract_repository_impl.dart';
import '../../domain/entities/job_post.dart';
import '../../domain/repositories/extract_repository.dart';

sealed class ExtractState {
  const ExtractState();
}

class ExtractIdle extends ExtractState {
  const ExtractIdle();
}

class Extracting extends ExtractState {
  const Extracting();
}

class ExtractDone extends ExtractState {
  const ExtractDone(this.job);
  final JobPost job;
}

class ExtractFailed extends ExtractState {
  const ExtractFailed(this.message);
  final String message;
}

class ExtractController extends Notifier<ExtractState> {
  CancelToken? _cancel;

  @override
  ExtractState build() {
    ref.onDispose(() => _cancel?.cancel());
    return const ExtractIdle();
  }

  void cancel() => _cancel?.cancel();

  Future<void> extract(String text) async {
    final input = text.trim();
    if (input.isEmpty || state is Extracting) return;
    state = const Extracting();
    final cancel = _cancel = CancelToken();
    try {
      final result = await ref
          .read(extractRepositoryProvider)
          .extractJobPost(
            text: input,
            model: ref.read(selectedModelProvider),
            cancel: cancel,
          );
      if (!ref.mounted) return;
      state = switch (result) {
        Extracted(:final job) => ExtractDone(job),
        NotExtracted(:final stopReason) => ExtractFailed(
          stopReasonNote(stopReason) ?? 'No fields came back. Try again.',
        ),
      };
    } catch (e) {
      if (ref.mounted) {
        state = ExtractFailed(
          reportError(e, cancelled: cancel.isCancelled, tag: 'extract'),
        );
      }
    }
  }
}

final extractControllerProvider =
    NotifierProvider<ExtractController, ExtractState>(ExtractController.new);
