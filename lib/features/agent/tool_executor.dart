import 'dart:convert';

import 'task_store.dart';

/// What the tools can do on the phone. TaskStore and Reminders provide it in the app; tests
/// pass a fake, so tool behaviour is checked without a device.
abstract interface class ToolActions {
  Future<List<Task>> tasks();
  Future<Task> addTask({required String title, required String dueDate, required String priority});
  Future<Task?> completeTask(String id);
  Future<bool> scheduleReminder({required String text, required int minutesFromNow});
  DateTime now();
}

/// The result sent back to Claude as a tool_result block, plus a line for the screen.
class ToolOutcome {
  const ToolOutcome({required this.content, required this.summary, this.isError = false});
  final String content;
  final String summary;
  final bool isError;
}

/// Runs the tool_use blocks Claude returns. The tool names and input shapes come from
/// `AGENT_TOOLS` in the edge function; strict schemas guarantee the inputs match, but every
/// value is still checked here because the phone is where the action happens.
class ToolExecutor {
  const ToolExecutor(this.actions);
  final ToolActions actions;

  Future<ToolOutcome> run(String name, Map<String, dynamic> input) async {
    switch (name) {
      case 'list_tasks':
        final tasks = await actions.tasks();
        final today = actions.now().toIso8601String().substring(0, 10);
        return ToolOutcome(
          content: jsonEncode({'today': today, 'tasks': [for (final t in tasks) t.toJson()]}),
          summary: 'Read ${tasks.length} task${tasks.length == 1 ? '' : 's'}',
        );

      case 'add_task':
        final title = (input['title'] as String? ?? '').trim();
        final due = (input['due_date'] as String? ?? '').trim();
        final priority = input['priority'] as String? ?? 'medium';
        if (title.isEmpty) return _error('add_task needs a title.');
        if (due.isNotEmpty && DateTime.tryParse(due) == null) return _error('due_date must be YYYY-MM-DD.');
        if (!const {'low', 'medium', 'high'}.contains(priority)) return _error('priority must be low, medium or high.');
        final task = await actions.addTask(title: title, dueDate: due, priority: priority);
        return ToolOutcome(
          content: jsonEncode({'added': task.toJson()}),
          summary: 'Added "${task.title}"${due.isEmpty ? '' : ' for $due'}',
        );

      case 'complete_task':
        final id = input['task_id'] as String? ?? '';
        final task = await actions.completeTask(id);
        if (task == null) return _error('No task has id "$id". Call list_tasks for the ids.');
        return ToolOutcome(content: jsonEncode({'completed': task.toJson()}), summary: 'Completed "${task.title}"');

      case 'set_reminder':
        final text = (input['text'] as String? ?? '').trim();
        final minutes = input['minutes_from_now'];
        if (text.isEmpty) return _error('set_reminder needs text.');
        if (minutes is! int || minutes < 1 || minutes > 10080) {
          return _error('minutes_from_now must be a whole number from 1 to 10080.');
        }
        final scheduled = await actions.scheduleReminder(text: text, minutesFromNow: minutes);
        if (!scheduled) return _error('The user has not allowed notifications, so no reminder was set.');
        return ToolOutcome(
          content: jsonEncode({'scheduled_in_minutes': minutes, 'text': text}),
          summary: 'Reminder in $minutes min: "$text"',
        );

      default:
        return _error('Unknown tool "$name".');
    }
  }

  ToolOutcome _error(String message) => ToolOutcome(content: message, summary: message, isError: true);
}
