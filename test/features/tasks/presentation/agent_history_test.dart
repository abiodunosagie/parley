import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/errors/app_exception.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/core/storage/local_store.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/presentation/providers/current_user_provider.dart';
import 'package:parley/features/tasks/data/repositories/agent_repository_impl.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/domain/entities/agent_reply.dart';
import 'package:parley/features/tasks/domain/repositories/agent_repository.dart';
import 'package:parley/features/tasks/presentation/providers/agent_controller.dart';
import 'package:parley/features/tasks/presentation/providers/agent_history_provider.dart';

import '../../../helpers/fakes.dart';

/// Fails while [failing] is true, then answers.
class _Flaky implements AgentRepository {
  bool failing = true;

  @override
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  }) async {
    if (failing) {
      throw const AppException(
        'No connection. Check your internet and try again.',
      );
    }
    return const AgentReply(
      content: [
        {'type': 'text', 'text': 'Done.'},
      ],
      stopReason: 'end_turn',
    );
  }
}

void main() {
  late _Flaky claude;
  late ProviderContainer container;

  setUp(() async {
    claude = _Flaky();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuth(const AppUser(id: 'u1', email: 'a@b.c')),
        ),
        taskRepositoryProvider.overrideWithValue(MemoryTasks()),
        agentRepositoryProvider.overrideWithValue(claude),
        localStoreProvider.overrideWithValue(MemoryStore()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(currentUserIdProvider, (_, _) {});
    container.listen(agentHistoryProvider, (_, _) {});
    await pumpEventQueue();
  });

  test(
    'a first message that fails is not saved, the retry that works is',
    () async {
      final agent = container.read(agentControllerProvider.notifier);
      await agent.send('Add milk');
      expect(
        container.read(agentControllerProvider).notice,
        contains('No connection'),
      );
      expect(await container.read(agentHistoryProvider.future), isEmpty);

      claude.failing = false;
      await agent.send('Add milk');
      final saved = await container.read(agentHistoryProvider.future);
      expect(saved.single.title, 'Add milk');
    },
  );
}
