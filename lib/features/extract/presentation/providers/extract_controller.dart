// FILE: features/extract/presentation/providers/extract_controller.dart
// EXTRACT LOGIC: structured output. One request, one JSON object back, turned into a JobPost and
// saved to history. The screen shows one of four explicit states: idle, extracting, done, or
// failed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/saved_history.dart';
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

class ExtractController extends Notifier<ExtractState>
    with SavedHistory<ExtractState> {
  static const _uuid = Uuid();

  /// The request that owns the state. Anything that replaces the screen drops it, so a request
  /// still finishing can never overwrite what you opened since.
  CancelToken? _current;

  @override
  ExtractState build() {
    ref.onDispose(() => _current?.cancel());
    return const ExtractIdle();
  }

  @override
  String? get historyUserId => ref.read(currentUserIdProvider);

  @override
  ProviderOrFamily get historyList => extractHistoryProvider;

  void cancel() => _current?.cancel();

  void _abandon() {
    _current?.cancel();
    _current = null;
  }

  Future<void> extract(String text) async {
    final input = text.trim();
    if (input.isEmpty || state is Extracting) return;
    state = const Extracting();
    final cancel = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, cancel);
    try {
      final result = await ref
          .read(extractRepositoryProvider)
          .extractJobPost(
            text: input,
            model: ref.read(selectedModelProvider),
            cancel: cancel,
          );
      if (!stillMine()) return;
      _current = null;
      switch (result) {
        case Extracted(:final job):
          final done = ExtractDone(job, id: _uuid.v4(), input: input);
          state = done;
          await changeSaved(
            (userId) => ref.read(extractRepositoryProvider).save(userId, (
              id: done.id,
              input: done.input,
              job: done.job,
              savedAt: DateTime.now(),
            )),
          );
        case NotExtracted(:final stopReason):
          state = ExtractFailed(
            stopReasonNote(stopReason) ?? 'No fields came back. Try again.',
          );
      }
    } catch (e) {
      if (!stillMine()) return;
      _current = null;
      state = ExtractFailed(
        reportError(e, cancelled: cancel.isCancelled, tag: 'extract'),
      );
    }
  }

  Future<void> open(String id) async {
    final saved = await loadSaved(
      (userId) => ref.read(extractRepositoryProvider).load(userId, id),
    );
    if (!ref.mounted) return;
    _abandon();
    state = saved == null
        ? const ExtractFailed('That job post could not be opened.')
        : ExtractDone(saved.job, id: saved.id, input: saved.input);
  }

  Future<void> deleteSaved(String id) async {
    await changeSaved(
      (userId) => ref.read(extractRepositoryProvider).delete(userId, id),
    );
    if (!ref.mounted) return;
    if (state case ExtractDone(id: final shown) when shown == id) {
      state = const ExtractIdle();
    }
  }
}

final extractControllerProvider =
    NotifierProvider<ExtractController, ExtractState>(ExtractController.new);
