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
import 'package:parley/app/launch/launch_screen.dart';
import 'package:parley/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:parley/features/conversation/presentation/screens/chat_screen.dart';
import 'package:parley/features/conversation/presentation/screens/look_screen.dart';
import 'package:parley/features/conversation/presentation/screens/read_screen.dart';
import 'package:parley/features/extract/presentation/screens/extract_screen.dart';
import 'package:parley/features/home/presentation/screens/tools_screen.dart';
import 'package:parley/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:parley/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:parley/features/receipt/presentation/screens/receipt_screen.dart';
import 'package:parley/features/rewrite/presentation/screens/rewrite_screen.dart';
import 'package:parley/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:parley/features/tasks/presentation/screens/tasks_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/launch.dart';

Future<FakeAuth> _pumpApp(
  WidgetTester tester, {
  bool signedIn = false,
  Brightness brightness = Brightness.light,
  MemoryOnboarding? onboarding,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool waitForLaunch = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
        onboardingRepositoryProvider.overrideWithValue(
          onboarding ?? MemoryOnboarding(seen: true),
        ),
      ],
      child: const ParleyApp(),
    ),
  );
  if (waitForLaunch) await pumpPastLaunch(tester);
  return auth;
}

/// True when a tap at the centre of [finder] would reach it, not something drawn over it.
bool _tappable(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  final centre = box.localToGlobal(box.size.center(Offset.zero));
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, centre, tester.view.viewId);
  return result.path.any((entry) => entry.target == box);
}

void main() {
  testWidgets('a fresh install: splash once, the welcome pages, then sign-in', (
    tester,
  ) async {
    final onboarding = MemoryOnboarding();
    await _pumpApp(tester, onboarding: onboarding, waitForLaunch: false);
    await tester.pump();
    expect(find.byType(LaunchScreen), findsOneWidget);
    await pumpPastLaunch(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    for (var page = 0; page < 3; page++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    // The last page only offers Get started.
    expect(find.text('Skip'), findsNothing);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(onboarding.seen, isTrue);
    expect(onboarding.saves, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome pages fit a small phone with large text', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      onboarding: MemoryOnboarding(),
      size: const Size(320, 568),
      textScale: 1.6,
    );
    for (var page = 0; page < 4; page++) {
      final label = 'page ${page + 1}';
      expect(tester.takeException(), isNull, reason: label);
      final button = find.text(page < 3 ? 'Continue' : 'Get started');
      expect(_tappable(tester, button), isTrue, reason: label);
      if (page < 3) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets(
    'Skip on the first page goes straight to sign-in and is remembered',
    (tester) async {
      final onboarding = MemoryOnboarding();
      await _pumpApp(
        tester,
        signedIn: false,
        brightness: Brightness.light,
        onboarding: onboarding,
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(onboarding.seen, isTrue);
    },
  );

  testWidgets('a quick double tap on Continue moves one page, not two', (
    tester,
  ) async {
    await _pumpApp(tester, onboarding: MemoryOnboarding());
    await tester.tap(find.text('Continue'));
    // One frame to start the slide, then most of the way through it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 4'), findsOneWidget);
  });

  testWidgets('swiping back shows a welcome page finished, not playing again', (
    tester,
  ) async {
    await _pumpApp(tester, onboarding: MemoryOnboarding());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // Drag most of the way back and look at once: a page built fresh would still be invisible.
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 50));
    final first = find.ancestor(
      of: find.text('Is the ferry to Cacilhas running today?'),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(first.first).opacity, 1);
  });

  testWidgets('signing out after creating an account shows Welcome back', (
    tester,
  ) async {
    final auth = await _pumpApp(tester);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
    auth.emit(const AppUser(id: 'u1', email: 'me@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsNothing);
    expect(find.textContaining('Welcome'), findsOneWidget);
  });

  testWidgets('creating an account asks for first and last name', (
    tester,
  ) async {
    await _pumpApp(tester, signedIn: false, brightness: Brightness.light);
    expect(find.text('First name'), findsNothing);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your first name.'), findsOneWidget);
    expect(find.text('Enter your last name.'), findsOneWidget);
  });

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
