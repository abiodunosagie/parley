import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/agent/task_store.dart';
import 'package:parley/features/agent/tool_executor.dart';

class _FakePhone implements ToolActions {
  final List<Task> list = [];
  final List<(String, int)> reminders = [];
  bool notificationsAllowed = true;

  @override
  DateTime now() => DateTime(2026, 10, 23, 9);

  @override
  Future<List<Task>> tasks() async => list;

  @override
  Future<Task> addTask({
    required String title,
    required String dueDate,
    required String priority,
  }) async {
    final task = Task(
      id: 't${list.length + 1}',
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    list.add(task);
    return task;
  }

  @override
  Future<Task?> completeTask(String id) async {
    final i = list.indexWhere((t) => t.id == id);
    if (i < 0) return null;
    return list[i] = list[i].copyWith(done: true);
  }

  @override
  Future<bool> scheduleReminder({
    required String text,
    required int minutesFromNow,
  }) async {
    if (!notificationsAllowed) return false;
    reminders.add((text, minutesFromNow));
    return true;
  }
}

void main() {
  late _FakePhone phone;
  late ToolExecutor tools;

  setUp(() {
    phone = _FakePhone();
    tools = ToolExecutor(phone);
  });

  test('list_tasks returns today and every task as JSON', () async {
    await phone.addTask(title: 'Milk', dueDate: '2026-10-24', priority: 'high');
    final out = await tools.run('list_tasks', {});
    final json = jsonDecode(out.content) as Map<String, dynamic>;
    expect(json['today'], '2026-10-23');
    expect((json['tasks'] as List).single['title'], 'Milk');
    expect(out.isError, isFalse);
    expect(out.summary, 'Read 1 task');
  });

  test('add_task adds and reports the date', () async {
    final out = await tools.run('add_task', {
      'title': ' Buy milk ',
      'due_date': '2026-10-24',
      'priority': 'high',
    });
    expect(phone.list.single.title, 'Buy milk');
    expect(out.summary, 'Added "Buy milk" for 2026-10-24');
  });

  test(
    'add_task refuses a bad date, a bad priority and an empty title',
    () async {
      expect(
        (await tools.run('add_task', {
          'title': 'x',
          'due_date': 'tomorrow',
          'priority': 'low',
        })).isError,
        isTrue,
      );
      expect(
        (await tools.run('add_task', {
          'title': 'x',
          'due_date': '',
          'priority': 'urgent',
        })).isError,
        isTrue,
      );
      expect(
        (await tools.run('add_task', {
          'title': '  ',
          'due_date': '',
          'priority': 'low',
        })).isError,
        isTrue,
      );
      expect(phone.list, isEmpty);
    },
  );

  test(
    'complete_task marks the task, or tells Claude to look up the id',
    () async {
      await phone.addTask(title: 'Milk', dueDate: '', priority: 'low');
      expect(
        (await tools.run('complete_task', {'task_id': 't1'})).summary,
        'Completed "Milk"',
      );
      expect(phone.list.single.done, isTrue);
      final missing = await tools.run('complete_task', {'task_id': 'nope'});
      expect(missing.isError, isTrue);
      expect(missing.content, contains('list_tasks'));
    },
  );

  test('set_reminder checks the range and the permission', () async {
    expect(
      (await tools.run('set_reminder', {
        'text': 'Stretch',
        'minutes_from_now': 2,
      })).isError,
      isFalse,
    );
    expect(phone.reminders.single, ('Stretch', 2));
    expect(
      (await tools.run('set_reminder', {
        'text': 'x',
        'minutes_from_now': 0,
      })).isError,
      isTrue,
    );
    expect(
      (await tools.run('set_reminder', {
        'text': 'x',
        'minutes_from_now': 20000,
      })).isError,
      isTrue,
    );
    phone.notificationsAllowed = false;
    final denied = await tools.run('set_reminder', {
      'text': 'x',
      'minutes_from_now': 5,
    });
    expect(denied.isError, isTrue);
    expect(denied.content, contains('not allowed notifications'));
  });

  test('an unknown tool is an error result, never a crash', () async {
    final out = await tools.run('delete_everything', {});
    expect(out.isError, isTrue);
  });
}
