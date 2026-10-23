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
      child: switch (tasks) {
        AsyncData(:final value) when value.isEmpty => _Message(
          'No tasks yet. Ask Parley to add one.',
          colors.muted,
        ),
        AsyncData(:final value) => ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: value.length,
          itemBuilder: (context, i) => TaskTile(
            task: value[i],
            onToggle: (done) => controller.setDone(value[i].id, done: done),
            onDelete: () => controller.remove(value[i].id),
          ),
        ),
        AsyncError() => _Message(
          'Could not load your tasks. Restart the app to try again.',
          colors.danger,
        ),
        _ => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(text, style: TextStyle(color: color)),
  );
}
