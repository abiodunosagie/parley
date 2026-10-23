// FILE: features/tasks/presentation/providers/task_list_controller.dart
// The signed-in account's task list, shown at the top of Tasks and changed by the agent's tools
// or by you (tick, swipe to delete). An AsyncNotifier, so the screen sees loading and error states
// explicitly instead of an empty list. Rebuilds when the account changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';

class TaskListController extends AsyncNotifier<List<Task>> {
  static const _uuid = Uuid();
  // Short ids are easy for Claude to repeat back in complete_task; 8 hex chars is plenty per phone.
  static const _idLength = 8;

  String? _userId;

  @override
  Future<List<Task>> build() async {
    final userId = _userId = ref.watch(
      currentUserProvider.select((user) => user.value?.id),
    );
    if (userId == null) return const [];
    return ref.read(taskRepositoryProvider).load(userId);
  }

  /// The list once it has loaded from storage. The agent's list_tasks tool reads this.
  Future<List<Task>> current() => future;

  Future<Task> add({
    required String title,
    required String dueDate,
    required TaskPriority priority,
  }) async {
    final (userId, tasks) = await _ready();
    final task = Task(
      id: _uuid.v4().substring(0, _idLength),
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    await _replace(userId, [...tasks, task]);
    return task;
  }

  /// Returns the task that changed, or null when no task has that id.
  Future<Task?> setDone(String id, {bool done = true}) async {
    final (userId, tasks) = await _ready();
    Task? changed;
    final next = [
      for (final t in tasks)
        if (t.id == id) changed = t.copyWith(done: done) else t,
    ];
    if (changed != null) await _replace(userId, next);
    return changed;
  }

  Future<void> remove(String id) async {
    final (userId, tasks) = await _ready();
    await _replace(userId, [
      for (final t in tasks)
        if (t.id != id) t,
    ]);
  }

  Future<void> _replace(String userId, List<Task> tasks) async {
    state = AsyncData(tasks);
    await ref.read(taskRepositoryProvider).save(userId, tasks);
  }

  /// Waits for the saved list, then checks the account did not change meanwhile, so a change
  /// started under one account can never be saved into another account's list.
  Future<(String, List<Task>)> _ready() async {
    final userId = _userId;
    final tasks = await future;
    if (!ref.mounted || userId == null || userId != _userId) {
      throw StateError('The account changed while saving a task.');
    }
    return (userId, tasks);
  }
}

final taskListControllerProvider =
    AsyncNotifierProvider<TaskListController, List<Task>>(
      TaskListController.new,
    );
