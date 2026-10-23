// FILE: core/env.dart
// The two public settings the app is built with (Supabase URL and publishable key).
// They come from config/parley.json through `--dart-define-from-file`, never from code.

/// Build-time settings, passed with `--dart-define-from-file=config/parley.json`.
///
/// Only the Supabase URL and the publishable key live in the app. Both are public by design:
/// the Claude key stays on the server, inside the `claude` edge function.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
