// Captures what a brand-new install sees: the launch animation, the four welcome pages, and
// sign-in and create-account. Run on a Simulator without Parley installed (flutter drive removes
// it afterwards), with the command in test_driver/integration_test.dart and
// --target=integration_test/first_run_test.dart. Images go to build/first_run/ for review.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:parley/app/app.dart';
import 'package:parley/core/config/env.dart';
import 'package:parley/core/session/access_token_provider.dart';
import 'package:parley/core/storage/preferences_provider.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run', (tester) async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          accessTokenProvider.overrideWith(
            (ref) => ref.watch(authRepositoryProvider).accessToken,
          ),
        ],
        child: const ParleyApp(),
      ),
    );
    Future<void> shot(String name) => binding.takeScreenshot('first_run_$name');

    await tester.pump(const Duration(milliseconds: 700));
    await shot('launch_meeting');
    await tester.pump(const Duration(milliseconds: 1200));
    await shot('launch_done');
    // The splash holds the finished mark on a timer, so move the clock on rather than settle.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();
    for (var page = 1; page <= 4; page++) {
      await tester.pump(const Duration(milliseconds: 1800));
      await shot('welcome_$page');
      if (page < 4) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await shot('sign_in');
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await shot('create_account');
  });
}
