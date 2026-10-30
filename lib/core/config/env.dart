// FILE: core/config/env.dart
// The public settings the app is built with (Supabase URL and publishable key, plus an optional
// API base URL). They come from config/parley.json through `--dart-define-from-file`, never from code.

/// Build-time settings, passed with `--dart-define-from-file=config/parley.json`.
///
/// Only the Supabase URL and the publishable key live in the app. Both are public by design:
/// the Claude key stays on the server, inside the `claude` edge function.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Optional base URL of the NestJS API (github.com/abiodunosagie/parley-api), for example
  /// `https://parley-api.vercel.app`. Empty means the app calls the Supabase edge function.
  static const parleyApiUrl = String.fromEnvironment('PARLEY_API_URL');

  /// Where Claude requests go. Both backends speak the same contract, so this is the only switch.
  static Uri get claudeEndpoint => parleyApiUrl.isEmpty
      ? Uri.parse('$supabaseUrl/functions/v1/claude')
      : Uri.parse('$parleyApiUrl/v1/claude');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
