// FILE: features/tasks/presentation/providers/agent_controller.dart
// Connects the Tasks screen to the agent loop (domain/services/agent_loop.dart): keeps the lines
// on screen, the running/idle status, the note under the conversation, and the model the
// conversation is locked to.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../../domain/entities/agent_item.dart';
import '../../domain/services/agent_loop.dart';
import '../../domain/services/tool_executor.dart';
import 'phone_tool_actions.dart';

@immutable
class AgentState {
  const AgentState({
    this.items = const [],
    this.running = false,
    this.notice,
    this.model,
  });
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
    items: items ?? this.items,
    running: running ?? this.running,
    notice: notice == null ? this.notice : notice(),
    model: model,
  );
}

class AgentController extends Notifier<AgentState> {
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

  void stop() => _current?.cancel();

  void reset() {
    _current?.cancel();
    _current = null;
    _loop.clear();
    state = const AgentState();
  }

  Future<void> send(String text) async {
    if (state.running) return;
    final token = _current = CancelToken();
    bool isCurrent() => ref.mounted && identical(_current, token);
    final selected = ref.read(selectedModelProvider);
    final model = state.model ?? selected;

    state = AgentState(
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
  }
}

final agentControllerProvider = NotifierProvider<AgentController, AgentState>(
  AgentController.new,
);
