// FILE: main.dart
// START HERE. The app's entry point.
// Reads the Supabase settings (core/config/env.dart), connects to Supabase, opens the phone's
// preferences, wires the pieces that core cannot know about (the session token, the user's own
// Claude key, account clean-up), then starts the app.
// Run with: flutter run --dart-define-from-file=config/parley.json
// Read next: app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/missing_config_app.dart';
import 'core/config/env.dart';
import 'core/session/access_token_provider.dart';
import 'core/session/account_cleanup_provider.dart';
import 'core/session/own_api_key_provider.dart';
import 'core/storage/local_store.dart';
import 'core/storage/preferences_provider.dart';
import 'features/auth/data/repositories/api_key_repository_impl.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  // Opened before the first frame, so the router knows at once whether to show the welcome pages.
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        accessTokenProvider.overrideWith(
          (ref) => ref.watch(authRepositoryProvider).accessToken,
        ),
        ownApiKeyProvider.overrideWith((ref) {
          final auth = ref.watch(authRepositoryProvider);
          final keys = ref.watch(apiKeyRepositoryProvider);
          return () async {
            final userId = auth.currentUser?.id;
            return userId == null ? null : keys.read(userId);
          };
        }),
        accountCleanupsProvider.overrideWith(
          (ref) => [
            ref.watch(taskRepositoryProvider).forget,
            ref.watch(localStoreProvider).forgetUser,
            ref.watch(apiKeyRepositoryProvider).remove,
          ],
        ),
      ],
      child: const ParleyApp(),
    ),
  );
}
