// FILE: main.dart
// START HERE. The app's entry point.
// Reads the Supabase settings (core/config/env.dart), connects to Supabase, wires the pieces that
// core cannot know about (the session token, account clean-up), then starts the app.
// Run with: flutter run --dart-define-from-file=config/parley.json
// Read next: app/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/missing_config_app.dart';
import 'core/config/env.dart';
import 'core/session/access_token_provider.dart';
import 'core/session/account_cleanup_provider.dart';
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
  runApp(
    ProviderScope(
      overrides: [
        accessTokenProvider.overrideWith(
          (ref) => ref.watch(authRepositoryProvider).accessToken,
        ),
        accountCleanupsProvider.overrideWith(
          (ref) => [ref.watch(taskRepositoryProvider).forget],
        ),
      ],
      child: const ParleyApp(),
    ),
  );
}
