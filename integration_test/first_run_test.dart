// Captures what a brand-new install sees: the launch animation, the four welcome pages, and
// sign-in and create-account. Run on a Simulator without Parley installed (flutter drive removes
// it afterwards), with the command in test_driver/integration_test.dart and
// --target=integration_test/first_run_test.dart. Images go to build/first_run/ for review. The
// welcome pages start unseen in memory, so the run never depends on what the phone saved before.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:parley/app/app.dart';
import 'package:parley/core/config/env.dart';
import 'package:parley/core/session/access_token_provider.dart';
import 'package:parley/app/launch/launch_screen.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:parley/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:parley/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/launch.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run', (tester) async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(MemoryOnboarding()),
          accessTokenProvider.overrideWith(
            (ref) => ref.watch(authRepositoryProvider).accessToken,
          ),
        ],
        child: const ParleyApp(),
      ),
    );
    Future<void> shot(String name) => binding.takeScreenshot('first_run_$name');

    // Mid-meeting, then the finished mark, timed from the splash's own constants: the first
    // frame, the grace that starts the clock, then the animation's frames.
    await tester.pump();
    await tester.pump(LaunchScreen.firstFrameGrace);
    await tester.pump();
    await tester.pump(LaunchScreen.play ~/ 2);
    expect(find.byType(LaunchScreen), findsOneWidget);
    await shot('launch_meeting');
    await tester.pump(LaunchScreen.play ~/ 2);
    await shot('launch_done');
    await pumpPastLaunch(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    for (var page = 1; page <= 4; page++) {
      // Long enough for the longest exchange (five lines) to finish playing in.
      await tester.pump(const Duration(milliseconds: 2400));
      await shot('welcome_$page');
      if (page < 4) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    await shot('sign_in');
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('First name'), findsOneWidget);
    await shot('create_account');
  });
}
