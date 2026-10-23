// FILE: main.dart
// START HERE. The app's entry point.
// Reads the Supabase settings (lib/core/env.dart), connects to Supabase, then shows AuthGate,
// which decides between the sign-in screen and the four tabs. Also closes the keyboard when you
// tap outside a text field, on every screen.
// Read next: lib/features/auth/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/auth_gate.dart';
import 'app/theme.dart';
import 'core/env.dart';

/// Run with: flutter run --dart-define-from-file=config/parley.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.isConfigured) {
    runApp(const _MissingConfig());
    return;
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  runApp(const ProviderScope(child: ParleyApp()));
}

class ParleyApp extends StatelessWidget {
  const ParleyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parley',
      debugShowCheckedModeBanner: false,
      theme: parleyTheme(Brightness.light),
      darkTheme: parleyTheme(Brightness.dark),
      // Tapping anywhere that is not a text field closes the keyboard, on every screen. Without
      // this the keyboard stays up over the chat until the user finds a way to close it.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      home: const AuthGate(),
    );
  }
}

/// Shown when the app was started without `--dart-define-from-file`, instead of a blank crash.
class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Parley needs its config.\n\nRun:\nflutter run --dart-define-from-file=config/parley.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
