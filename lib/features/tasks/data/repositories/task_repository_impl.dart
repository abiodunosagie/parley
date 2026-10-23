// FILE: features/tasks/data/repositories/task_repository_impl.dart
// The real TaskRepository. Saves run one after another, so two quick changes cannot land on disk
// out of order, and a corrupt saved list starts fresh instead of breaking every later call.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local);
  final TaskLocalDataSource _local;

  Future<void> _saving = Future.value();

  @override
  Future<List<Task>> load(String userId) async {
    final raw = await _local.read(userId);
    if (raw == null) return const [];
    try {
      return [
        for (final t in jsonDecode(raw) as List)
          Task.fromJson(t as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Parley: saved tasks unreadable, starting empty ($e)');
      return const [];
    }
  }

  @override
  Future<void> save(String userId, List<Task> tasks) {
    final json = jsonEncode([for (final t in tasks) t.toJson()]);
    return _saving = _saving.then((_) => _local.write(userId, json));
  }

  @override
  Future<void> forget(String userId) => _local.remove(userId);
}

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(TaskLocalDataSource()),
);
