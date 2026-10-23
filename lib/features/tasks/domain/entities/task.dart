// FILE: features/tasks/domain/entities/task.dart
// One task on the list the agent manages. `id` is short on purpose so Claude can repeat it back
// in complete_task.

import 'package:flutter/foundation.dart';

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.priority,
    this.done = false,
  });

  final String id;
  final String title;

  /// YYYY-MM-DD, or empty when the task has no date.
  final String dueDate;
  final String priority;
  final bool done;

  Task copyWith({bool? done}) => Task(
    id: id,
    title: title,
    dueDate: dueDate,
    priority: priority,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'due_date': dueDate,
    'priority': priority,
    'done': done,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    dueDate: json['due_date'] as String? ?? '',
    priority: json['priority'] as String? ?? 'medium',
    done: json['done'] as bool? ?? false,
  );
}
