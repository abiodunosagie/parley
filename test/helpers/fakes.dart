// Fakes shared by the tests: an account system and a task store that live in memory.

import 'dart:async';

import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/domain/repositories/auth_repository.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:parley/features/tasks/domain/repositories/task_repository.dart';

class FakeAuth implements AuthRepository {
  FakeAuth([this.currentUser]);

  @override
  AppUser? currentUser;
  final _changes = StreamController<AppUser?>.broadcast();
  final calls = <String>[];
  Object? deleteError;

  void emit(AppUser? user) {
    currentUser = user;
    _changes.add(user);
  }

  @override
  Stream<AppUser?> watchUser() => _changes.stream;

  @override
  Future<String> accessToken({bool fresh = false}) async => 'token';

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn');
    emit(AppUser(id: 'u1', email: email));
  }

  @override
  Future<void> signOut({bool everywhere = true}) async {
    calls.add(everywhere ? 'signOut' : 'signOutLocal');
    emit(null);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    return SignUpOutcome.confirmEmail;
  }
}

class MemoryTasks implements TaskRepository {
  final saved = <String, List<Task>>{};

  @override
  Future<void> forget(String userId) async => saved.remove(userId);

  @override
  Future<List<Task>> load(String userId) async => saved[userId] ?? const [];

  @override
  Future<void> save(String userId, List<Task> tasks) async =>
      saved[userId] = tasks;
}
