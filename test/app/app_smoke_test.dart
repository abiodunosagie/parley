import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/app/app.dart';
import 'package:parley/core/session/access_token_provider.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/domain/repositories/auth_repository.dart';
import 'package:parley/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:parley/features/conversation/presentation/screens/chat_screen.dart';
import 'package:parley/features/conversation/presentation/screens/look_screen.dart';
import 'package:parley/features/extract/presentation/screens/extract_screen.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:parley/features/tasks/domain/repositories/task_repository.dart';
import 'package:parley/features/tasks/presentation/screens/tasks_screen.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth(this.currentUser);
  @override
  AppUser? currentUser;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> watchUser() => _changes.stream;

  @override
  Future<String> accessToken({bool fresh = false}) async => 'token';

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signIn({required String email, required String password}) async {
    currentUser = AppUser(id: 'u1', email: email);
    _changes.add(currentUser);
  }

  @override
  Future<void> signOut({bool everywhere = true}) async {
    currentUser = null;
    _changes.add(null);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
  }) async => SignUpOutcome.signedIn;
}

class _MemoryTasks implements TaskRepository {
  @override
  Future<void> forget(String userId) async {}
  @override
  Future<List<Task>> load(String userId) async => const [];
  @override
  Future<void> save(String userId, List<Task> tasks) async {}
}

Future<_FakeAuth> _pumpApp(
  WidgetTester tester, {
  required bool signedIn,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final auth = _FakeAuth(
    signedIn ? const AppUser(id: 'u1', email: 'me@example.com') : null,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accessTokenProvider.overrideWithValue(auth.accessToken),
        taskRepositoryProvider.overrideWithValue(_MemoryTasks()),
      ],
      child: const ParleyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('signed out shows sign-in (${brightness.name})', (
      tester,
    ) async {
      await _pumpApp(tester, signedIn: false, brightness: brightness);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'signed in opens Chat and every tab renders (${brightness.name})',
      (tester) async {
        await _pumpApp(tester, signedIn: true, brightness: brightness);
        expect(find.byType(ChatScreen), findsOneWidget);
        for (final (label, screen) in [
          ('Look', LookScreen),
          ('Extract', ExtractScreen),
          ('Tasks', TasksScreen),
          ('Chat', ChatScreen),
        ]) {
          await tester.tap(find.bySemanticsLabel(label));
          await tester.pumpAndSettle();
          expect(find.byType(screen), findsOneWidget, reason: '$label tab');
          expect(tester.takeException(), isNull, reason: '$label tab');
        }
      },
    );
  }

  testWidgets('signing out moves to the sign-in screen by itself', (
    tester,
  ) async {
    final auth = await _pumpApp(
      tester,
      signedIn: true,
      brightness: Brightness.light,
    );
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
