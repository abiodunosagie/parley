// FILE: features/agent/task_store.dart
// The task list the agent manages, saved on the phone (SharedPreferences), one list
// per signed-in account.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../auth/auth_controller.dart';

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

/// The task list Claude manages through tools. It lives on the phone (SharedPreferences), one
/// list per signed-in account; the server never sees it except as the tool results the app sends.
class TaskStore extends Notifier<List<Task>> {
  static String _keyFor(String userId) => 'parley.tasks.$userId';

  /// Removes an account's saved tasks from this phone (used when the account is deleted).
  static Future<void> forget(String userId) async =>
      (await SharedPreferences.getInstance()).remove(_keyFor(userId));

  late String? _key;
  static const _uuid = Uuid();
  // Short ids are easy for Claude to repeat back in complete_task; 8 hex chars is plenty per phone.
  static const _idLength = 8;

  // Every change waits for the saved list first, so an early add cannot be overwritten by it.
  late Future<void> _loaded;

  @override
  List<Task> build() {
    final userId = ref.watch(currentUserProvider).value?.id;
    _key = userId == null ? null : _keyFor(userId);
    _loaded = _load();
    return const [];
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null || !ref.mounted) return;
    try {
      state = [
        for (final t in jsonDecode(raw) as List)
          Task.fromJson(t as Map<String, dynamic>),
      ];
    } catch (e) {
      // A corrupt saved list starts fresh instead of breaking every later task call.
      debugPrint('Parley: saved tasks unreadable, starting empty ($e)');
    }
  }

  /// The list once it has loaded from storage. The agent's list_tasks tool reads this.
  Future<List<Task>> current() async {
    await _loaded;
    return state;
  }

  // Saves run one after another, so two quick changes cannot land on disk out of order.
  Future<void> _saving = Future.value();

  Future<void> _save() {
    final key = _key;
    if (key == null) return Future.value();
    final json = jsonEncode([for (final t in state) t.toJson()]);
    return _saving = _saving.then(
      (_) async => (await SharedPreferences.getInstance()).setString(key, json),
    );
  }

  Future<Task> add({
    required String title,
    required String dueDate,
    required String priority,
  }) async {
    await _loaded;
    final task = Task(
      id: _uuid.v4().substring(0, _idLength),
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    state = [...state, task];
    await _save();
    return task;
  }

  /// Returns the task that changed, or null when no task has that id.
  Future<Task?> setDone(String id, {bool done = true}) async {
    await _loaded;
    Task? changed;
    state = [
      for (final t in state)
        if (t.id == id) changed = t.copyWith(done: done) else t,
    ];
    if (changed != null) await _save();
    return changed;
  }

  Future<void> remove(String id) async {
    await _loaded;
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    await _save();
  }
}

final taskStoreProvider = NotifierProvider<TaskStore, List<Task>>(
  TaskStore.new,
);
