import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/app/app.dart';
import 'package:parley/core/session/access_token_provider.dart';
import 'package:parley/core/speech/speech_service.dart';
import 'package:parley/core/storage/local_store.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:parley/features/conversation/presentation/screens/chat_screen.dart';
import 'package:parley/features/conversation/presentation/screens/look_screen.dart';
import 'package:parley/features/conversation/presentation/screens/read_screen.dart';
import 'package:parley/features/extract/presentation/screens/extract_screen.dart';
import 'package:parley/features/home/presentation/screens/tools_screen.dart';
import 'package:parley/features/receipt/presentation/screens/receipt_screen.dart';
import 'package:parley/features/rewrite/presentation/screens/rewrite_screen.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/presentation/screens/tasks_screen.dart';

import '../helpers/fakes.dart';

Future<FakeAuth> _pumpApp(
  WidgetTester tester, {
  required bool signedIn,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final auth = FakeAuth(
    signedIn ? const AppUser(id: 'u1', email: 'me@example.com') : null,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accessTokenProvider.overrideWithValue(auth.accessToken),
        taskRepositoryProvider.overrideWithValue(MemoryTasks()),
        localStoreProvider.overrideWithValue(MemoryStore()),
        speechServiceProvider.overrideWithValue(FakeSpeech()),
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
          ('Read', ReadScreen),
          ('Tasks', TasksScreen),
          ('Tools', ToolsScreen),
          ('Chat', ChatScreen),
        ]) {
          await tester.tap(find.bySemanticsLabel(label));
          await tester.pumpAndSettle();
          expect(find.byType(screen), findsOneWidget, reason: '$label tab');
          expect(tester.takeException(), isNull, reason: '$label tab');
        }
        await tester.tap(find.bySemanticsLabel('Tools'));
        await tester.pumpAndSettle();
        for (final (title, screen) in [
          ('Rewrite', RewriteScreen),
          ('Receipts', ReceiptScreen),
          ('Extract', ExtractScreen),
        ]) {
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          expect(find.byType(screen), findsOneWidget, reason: '$title tool');
          expect(tester.takeException(), isNull, reason: '$title tool');
          // The app bar title is shown in full on a phone-width screen, never cut to "Rec...".
          final heading = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text(title),
            ),
          );
          expect(heading.didExceedMaxLines, isFalse, reason: '$title title');
          await tester.pageBack();
          await tester.pumpAndSettle();
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
