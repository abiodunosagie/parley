// FILE: features/rewrite/presentation/providers/rewrite_controller.dart
// REWRITE LOGIC: pick a style (shorter, formal, friendly, fix grammar, translate), and the
// rewrite streams in as Claude writes it. Finished rewrites are saved to history.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/rewrite_repository_impl.dart';
import '../../domain/entities/rewrite.dart';
import '../../domain/entities/rewrite_style.dart';
import '../../domain/repositories/rewrite_repository.dart';
import 'rewrite_history_provider.dart';

enum RewriteStatus { idle, writing, done, failed }

@immutable
class RewriteState {
  const RewriteState({
    this.id,
    this.input = '',
    this.style = RewriteStyle.shorter,
    this.language = 'French',
    this.output = '',
    this.status = RewriteStatus.idle,
    this.notice,
  });

  /// The saved rewrite on screen, or null while nothing has been saved.
  final String? id;

  /// The text that was rewritten (the text box holds what you are typing now).
  final String input;
  final RewriteStyle style;
  final String language;
  final String output;
  final RewriteStatus status;
  final String? notice;

  bool get writing => status == RewriteStatus.writing;

  RewriteState copyWith({
    String? Function()? id,
    String? input,
    RewriteStyle? style,
    String? language,
    String? output,
    RewriteStatus? status,
    String? Function()? notice,
  }) => RewriteState(
    id: id == null ? this.id : id(),
    input: input ?? this.input,
    style: style ?? this.style,
    language: language ?? this.language,
    output: output ?? this.output,
    status: status ?? this.status,
    notice: notice == null ? this.notice : notice(),
  );
}

class RewriteController extends Notifier<RewriteState> {
  static const _uuid = Uuid();
  CancelToken? _current;

  @override
  RewriteState build() {
    ref.onDispose(() => _current?.cancel());
    return const RewriteState();
  }

  String? get _userId => ref.read(currentUserProvider).value?.id;

  void setStyle(RewriteStyle style) => state = state.copyWith(style: style);
  void setLanguage(String language) =>
      state = state.copyWith(language: language);
  void stop() => _current?.cancel();

  void reset() {
    _current?.cancel();
    _current = null;
    state = RewriteState(style: state.style, language: state.language);
  }

  Future<void> run(String text) async {
    final input = text.trim();
    if (input.isEmpty || state.writing) return;
    final token = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, token);
    state = state.copyWith(
      id: () => null,
      input: input,
      output: '',
      status: RewriteStatus.writing,
      notice: () => null,
    );

    final output = StringBuffer();
    String? notice;
    var finished = false;
    try {
      final events = ref
          .read(rewriteRepositoryProvider)
          .rewrite(
            text: input,
            instruction: state.style.instruction(language: state.language),
            model: ref.read(selectedModelProvider),
            cancel: token,
          );
      await for (final event in events) {
        if (!stillMine()) return;
        switch (event) {
          case RewriteText(:final text):
            output.write(text);
            state = state.copyWith(output: output.toString());
          case RewriteDone(:final stopReason):
            finished = true;
            notice = stopReasonNote(stopReason);
          case RewriteFailed(:final message):
            finished = true;
            notice = message;
        }
      }
      if (!finished) {
        notice = token.isCancelled ? 'Stopped.' : 'The connection dropped.';
      }
    } catch (e) {
      notice = reportError(e, cancelled: token.isCancelled, tag: 'rewrite');
    }
    if (!stillMine()) return;
    _current = null;
    final ok = finished && notice == null && output.isNotEmpty;
    state = state.copyWith(
      status: ok ? RewriteStatus.done : RewriteStatus.failed,
      notice: () => notice,
    );
    if (ok) await _save();
  }

  Future<void> open(String id) async {
    final userId = _userId;
    if (userId == null) return;
    final saved = await ref.read(rewriteRepositoryProvider).load(userId, id);
    if (!ref.mounted) return;
    _current?.cancel();
    _current = null;
    state = saved == null
        ? state.copyWith(notice: () => 'That rewrite could not be opened.')
        : RewriteState(
            id: saved.id,
            input: saved.input,
            style: saved.style,
            language: saved.language,
            output: saved.output,
            status: RewriteStatus.done,
          );
  }

  Future<void> deleteSaved(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(rewriteRepositoryProvider).delete(userId, id);
    if (!ref.mounted) return;
    ref.invalidate(rewriteHistoryProvider);
    if (state.id == id) reset();
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null) return;
    final rewrite = Rewrite(
      id: _uuid.v4(),
      input: state.input,
      style: state.style,
      language: state.language,
      output: state.output,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(rewriteRepositoryProvider).save(userId, rewrite);
      if (!ref.mounted) return;
      state = state.copyWith(id: () => rewrite.id);
      ref.invalidate(rewriteHistoryProvider);
    } catch (e) {
      reportError(e, cancelled: false, tag: 'history');
    }
  }
}

final rewriteControllerProvider =
    NotifierProvider<RewriteController, RewriteState>(RewriteController.new);
