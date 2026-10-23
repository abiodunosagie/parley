// FILE: features/tasks/presentation/widgets/task_panel.dart
// The task list at the top of Tasks, capped in height so the conversation always has room.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/parley_colors.dart';
import '../providers/task_list_controller.dart';
import 'task_tile.dart';

class TaskPanel extends ConsumerWidget {
  const TaskPanel({super.key});

  static const _maxHeight = 210.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListControllerProvider);
    final controller = ref.read(taskListControllerProvider.notifier);
    final colors = context.colors;

    return Container(
      constraints: const BoxConstraints(maxHeight: _maxHeight),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tasks yet. Ask Parley to add one.',
                style: TextStyle(color: colors.muted),
              ),
            )
          : ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: tasks.length,
              itemBuilder: (context, i) => TaskTile(
                task: tasks[i],
                onToggle: (done) => controller.setDone(tasks[i].id, done: done),
                onDelete: () => controller.remove(tasks[i].id),
              ),
            ),
    );
  }
}
