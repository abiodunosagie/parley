// FILE: features/tasks/presentation/providers/phone_tool_actions.dart
// The real phone behind the agent's tools: the task list and local reminders. Tests pass a fake
// ToolActions instead, so the tools are checked without a device.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/services/tool_executor.dart';
import 'task_list_controller.dart';

class PhoneToolActions implements ToolActions {
  PhoneToolActions(this._ref);
  final Ref _ref;

  TaskListController get _tasks =>
      _ref.read(taskListControllerProvider.notifier);

  @override
  Future<List<Task>> tasks() => _tasks.current();

  @override
  Future<Task> addTask({
    required String title,
    required String dueDate,
    required TaskPriority priority,
  }) => _tasks.add(title: title, dueDate: dueDate, priority: priority);

  @override
  Future<Task?> completeTask(String id) => _tasks.setDone(id);

  @override
  Future<bool> scheduleReminder({
    required String text,
    required int minutesFromNow,
  }) => _ref
      .read(reminderRepositoryProvider)
      .schedule(text: text, minutesFromNow: minutesFromNow);

  @override
  DateTime now() => DateTime.now();
}
