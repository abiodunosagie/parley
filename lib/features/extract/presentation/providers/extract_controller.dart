// FILE: features/extract/presentation/providers/extract_controller.dart
// EXTRACT LOGIC: structured output. One request, one JSON object back, turned into a JobPost and
// saved to history. The screen shows one of four explicit states: idle, extracting, done, or
// failed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/extract_repository_impl.dart';
import '../../domain/entities/job_post.dart';
import '../../domain/repositories/extract_repository.dart';
import 'extract_history_provider.dart';

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
  const ExtractDone(this.job, {required this.id, required this.input});
  final JobPost job;

  /// The saved entry and the text it came from, so history can put both back on screen.
  final String id;
  final String input;
}

class ExtractFailed extends ExtractState {
  const ExtractFailed(this.message);
  final String message;
}

class ExtractController extends Notifier<ExtractState> {
  static const _uuid = Uuid();
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
      switch (result) {
        case Extracted(:final job):
          final done = ExtractDone(job, id: _uuid.v4(), input: input);
          state = done;
          await _save(done);
        case NotExtracted(:final stopReason):
          state = ExtractFailed(
            stopReasonNote(stopReason) ?? 'No fields came back. Try again.',
          );
      }
    } catch (e) {
      if (ref.mounted) {
        state = ExtractFailed(
          reportError(e, cancelled: cancel.isCancelled, tag: 'extract'),
        );
      }
    }
  }

  Future<void> open(String id) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) return;
    final saved = await ref.read(extractRepositoryProvider).load(userId, id);
    if (!ref.mounted) return;
    _cancel?.cancel();
    state = saved == null
        ? const ExtractFailed('That job post could not be opened.')
        : ExtractDone(saved.job, id: saved.id, input: saved.input);
  }

  Future<void> deleteSaved(String id) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) return;
    await ref.read(extractRepositoryProvider).delete(userId, id);
    if (!ref.mounted) return;
    ref.invalidate(extractHistoryProvider);
    if (state case ExtractDone(id: final shown) when shown == id) {
      state = const ExtractIdle();
    }
  }

  Future<void> _save(ExtractDone done) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) return;
    try {
      await ref.read(extractRepositoryProvider).save(userId, (
        id: done.id,
        input: done.input,
        job: done.job,
        savedAt: DateTime.now(),
      ));
      if (ref.mounted) ref.invalidate(extractHistoryProvider);
    } catch (e) {
      reportError(e, cancelled: false, tag: 'history');
    }
  }
}

final extractControllerProvider =
    NotifierProvider<ExtractController, ExtractState>(ExtractController.new);
