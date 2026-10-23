// FILE: features/tasks/data/datasources/task_local_datasource.dart
// Reads and writes one account's task list as JSON in SharedPreferences, under
// `parley.tasks.<userId>`.

import 'package:shared_preferences/shared_preferences.dart';

class TaskLocalDataSource {
  static String _keyFor(String userId) => 'parley.tasks.$userId';

  Future<String?> read(String userId) async =>
      (await SharedPreferences.getInstance()).getString(_keyFor(userId));

  Future<void> write(String userId, String json) async =>
      (await SharedPreferences.getInstance()).setString(_keyFor(userId), json);

  Future<void> remove(String userId) async =>
      (await SharedPreferences.getInstance()).remove(_keyFor(userId));
}
