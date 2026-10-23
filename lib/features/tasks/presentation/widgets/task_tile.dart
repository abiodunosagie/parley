// FILE: features/tasks/presentation/widgets/task_tile.dart
// One task: tick to complete, swipe left to delete. The small grey line shows the due date,
// priority and the short id Claude uses in complete_task.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });
  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colors.danger,
        child: Icon(Icons.delete_outline, color: colors.background),
      ),
      child: CheckboxListTile(
        dense: true,
        value: task.done,
        onChanged: (value) => onToggle(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          task.title,
          style: TextStyle(
            color: colors.ink,
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          [
            if (task.dueDate.isNotEmpty) task.dueDate,
            '${task.priority.name} priority',
            'id ${task.id}',
          ].join(' · '),
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
      ),
    );
  }
}
