import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/tasks/data/repositories/agent_repository_impl.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/domain/entities/agent_item.dart';
import 'package:parley/features/tasks/domain/entities/agent_reply.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:parley/features/tasks/domain/repositories/agent_repository.dart';
import 'package:parley/features/tasks/presentation/providers/agent_controller.dart';
import 'package:parley/features/tasks/presentation/providers/task_list_controller.dart';

import '../../../helpers/fakes.dart';

class _SaysDone implements AgentRepository {
  @override
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  }) async => const AgentReply(
    content: [
      {'type': 'text', 'text': 'Done.'},
    ],
    stopReason: 'end_turn',
  );
}

void main() {
  late FakeAuth auth;
  late MemoryTasks tasks;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuth(const AppUser(id: 'a', email: 'a@example.com'));
    tasks = MemoryTasks();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        taskRepositoryProvider.overrideWithValue(tasks),
        agentRepositoryProvider.overrideWithValue(_SaysDone()),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'the agent controller works again after it is reset by a new sign-in',
    () async {
      // Regression: `late final` in build() threw LateInitializationError when Riverpod re-ran
      // build() on the same instance after ref.invalidate (SessionReset does that on sign-in).
      await container.read(agentControllerProvider.notifier).send('Hi');
      container.invalidate(agentControllerProvider);
      await container.read(agentControllerProvider.notifier).send('Hi again');
      expect(
        container
            .read(agentControllerProvider)
            .items
            .whereType<ClaudeSaid>()
            .single
            .text,
        'Done.',
      );
    },
  );

  test(
    'task list loads, saves per account, and switches with the account',
    () async {
      tasks.saved['a'] = const [
        Task(id: 't1', title: 'Old', dueDate: '', priority: TaskPriority.low),
      ];
      final sub = container.listen(taskListControllerProvider, (_, _) {});
      addTearDown(sub.close);
      expect(
        await container.read(taskListControllerProvider.future),
        hasLength(1),
      );

      await container
          .read(taskListControllerProvider.notifier)
          .add(title: 'Milk', dueDate: '', priority: TaskPriority.high);
      expect(tasks.saved['a']!.map((t) => t.title), ['Old', 'Milk']);

      auth.emit(const AppUser(id: 'b', email: 'b@example.com'));
      await pumpEventQueue();
      expect(await container.read(taskListControllerProvider.future), isEmpty);
      expect(
        tasks.saved['a'],
        hasLength(2),
        reason: 'account a keeps its own list',
      );
    },
  );
}
