// FILE: features/tasks/presentation/providers/agent_controller.dart
// Connects the Tasks screen to the agent loop (domain/services/agent_loop.dart): keeps the lines
// on screen, the running/idle status, the note under the conversation, and the model the
// conversation is locked to. Saves each conversation so it can be opened again from history.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/saved_history.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/agent_history_repository_impl.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../../domain/entities/agent_item.dart';
import '../../domain/entities/agent_session.dart';
import '../../domain/services/agent_loop.dart';
import '../../domain/services/tool_executor.dart';
import 'agent_history_provider.dart';
import 'phone_tool_actions.dart';

@immutable
class AgentState {
  const AgentState({
    this.id,
    this.items = const [],
    this.running = false,
    this.notice,
    this.model,
  });

  /// The saved conversation's id. Null until the first message is sent.
  final String? id;
  final List<AgentItem> items;
  final bool running;
  final String? notice;

  /// The model this conversation runs on, fixed at its first message. Claude's thinking blocks
  /// are tied to the model that wrote them, so switching mid-conversation would break the replay.
  final ClaudeModel? model;

  bool get isEmpty => items.isEmpty;

  AgentState copyWith({
    List<AgentItem>? items,
    bool? running,
    String? Function()? notice,
  }) => AgentState(
    id: id,
    items: items ?? this.items,
    running: running ?? this.running,
    notice: notice == null ? this.notice : notice(),
    model: model,
  );
}

class AgentController extends Notifier<AgentState>
    with SavedHistory<AgentState> {
  static const _uuid = Uuid();

  // Built fresh in build(): Riverpod reruns build() on the same instance when the provider is
  // invalidated (for example after signing in again), so this must not be `late final`.
  late AgentLoop _loop;

  /// The run that owns the state; starting over replaces it (same pattern as the chat controller).
  CancelToken? _current;

  @override
  AgentState build() {
    _loop = AgentLoop(
      repository: ref.read(agentRepositoryProvider),
      executor: ToolExecutor(PhoneToolActions(ref)),
    );
    // Signing out disposes this controller: stop the running request so it stops spending.
    ref.onDispose(() => _current?.cancel());
    return const AgentState();
  }

  @override
  String? get historyUserId => ref.read(currentUserIdProvider);

  @override
  ProviderOrFamily get historyList => agentHistoryProvider;

  void stop() => _current?.cancel();

  void reset() {
    _current?.cancel();
    _current = null;
    _loop.clear();
    state = const AgentState();
  }

  /// Opens a saved conversation from history, ready to carry on.
  Future<void> open(String id) async {
    final saved = await loadSaved(
      (userId) => ref.read(agentHistoryRepositoryProvider).load(userId, id),
    );
    if (!ref.mounted) return;
    if (saved == null) {
      // Keep what is on screen; only say the saved one could not be read.
      state = state.copyWith(
        notice: () => 'That conversation could not be opened.',
      );
      return;
    }
    _current?.cancel();
    _current = null;
    _loop.restore(saved.transcript);
    state = AgentState(id: saved.id, items: saved.items, model: saved.model);
  }

  /// Deletes a saved conversation. Deleting the one on screen also clears the screen.
  Future<void> deleteSaved(String id) async {
    await changeSaved(
      (userId) => ref.read(agentHistoryRepositoryProvider).delete(userId, id),
    );
    if (ref.mounted && state.id == id) reset();
  }

  Future<void> send(String text) async {
    if (state.running) return;
    final token = _current = CancelToken();
    bool isCurrent() => ref.mounted && identical(_current, token);
    final selected = ref.read(selectedModelProvider);
    final model = state.model ?? selected;

    state = AgentState(
      id: state.id ?? _uuid.v4(),
      items: [...state.items, UserSaid(text)],
      running: true,
      model: model,
    );
    final result = await _loop.run(
      text: text,
      model: model,
      cancel: token,
      isCurrent: isCurrent,
      onItem: (item) => state = state.copyWith(items: [...state.items, item]),
    );

    if (!isCurrent()) return;
    _current = null;
    final error = result.unexpectedError;
    if (error != null) reportError(error, cancelled: false, tag: 'agent');
    final notice =
        result.notice ??
        (model != selected
            ? 'This conversation stays on ${model.label}. Start a new one to use another model.'
            : null);
    state = state.copyWith(running: false, notice: () => notice);
    await _save();
  }

  Future<void> _save() async {
    final id = state.id;
    final model = state.model;
    // Nothing worth saving until Claude has answered at least once: a first message that failed
    // or was stopped stays on screen but does not fill history with dead conversations.
    if (id == null ||
        model == null ||
        !_loop.transcript.any((turn) => turn['role'] == 'assistant')) {
      return;
    }
    final session = AgentSession(
      id: id,
      model: model,
      items: state.items,
      transcript: _loop.transcript,
      updatedAt: DateTime.now(),
    );
    await changeSaved(
      (userId) =>
          ref.read(agentHistoryRepositoryProvider).save(userId, session),
    );
  }
}

final agentControllerProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);
