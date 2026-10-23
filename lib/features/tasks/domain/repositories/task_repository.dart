// FILE: features/tasks/domain/repositories/task_repository.dart
// Where each account's task list is saved. Implemented with SharedPreferences in
// data/repositories/task_repository_impl.dart.

import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> load(String userId);
  Future<void> save(String userId, List<Task> tasks);

  /// Removes an account's tasks from this phone (after the account is deleted).
  Future<void> forget(String userId);
}
