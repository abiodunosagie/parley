import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and loads one list per account', () async {
    final repo = TaskRepositoryImpl(TaskLocalDataSource());
    await repo.save('a', const [
      Task(
        id: '1',
        title: 'Milk',
        dueDate: '2026-10-24',
        priority: TaskPriority.high,
      ),
    ]);
    expect((await repo.load('a')).single.priority, TaskPriority.high);
    expect(await repo.load('b'), isEmpty);
    await repo.forget('a');
    expect(await repo.load('a'), isEmpty);
  });

  test('quick saves land in order', () async {
    final repo = TaskRepositoryImpl(TaskLocalDataSource());
    final first = repo.save('a', const [
      Task(id: '1', title: 'One', dueDate: '', priority: TaskPriority.low),
    ]);
    final second = repo.save('a', const [
      Task(id: '1', title: 'One', dueDate: '', priority: TaskPriority.low),
      Task(id: '2', title: 'Two', dueDate: '', priority: TaskPriority.low),
    ]);
    await Future.wait([first, second]);
    expect(await repo.load('a'), hasLength(2));
  });

  test('a corrupt saved list starts fresh', () async {
    SharedPreferences.setMockInitialValues({'parley.tasks.a': 'not json'});
    expect(await TaskRepositoryImpl(TaskLocalDataSource()).load('a'), isEmpty);
  });
}
