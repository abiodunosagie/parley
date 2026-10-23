import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';
import '../agent/task_store.dart';

/// The signed-in user, or null. Every screen behind the gate rebuilds when this changes.
final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = Supabase.instance.client.auth;
  return auth.onAuthStateChange.map((event) => event.session?.user);
});

@immutable
class AuthState {
  const AuthState({this.busy = false, this.error, this.info});
  final bool busy;
  final String? error;

  /// Shown after sign-up when the project asks people to confirm their email first.
  final String? info;
}

/// Email and password accounts through Supabase Auth. Passwords go straight to Supabase over
/// HTTPS; the app never stores them.
class AuthController extends Notifier<AuthState> {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  AuthState build() => const AuthState();

  static String? checkEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim()) ? null : 'Enter a valid email address.';

  static String? checkPassword(String password) =>
      password.length >= 8 ? null : 'Use at least 8 characters.';

  Future<void> signIn(String email, String password) =>
      _run(() => _auth.signInWithPassword(email: email.trim(), password: password));

  Future<void> signUp(String email, String password) => _run(() async {
        final result = await _auth.signUp(email: email.trim(), password: password);
        // No session means the project requires email confirmation before the first sign-in.
        if (result.session == null && ref.mounted) {
          state = const AuthState(info: 'Check your inbox and confirm your email, then sign in.');
        }
      });

  Future<void> signOut() => _auth.signOut();

  /// Deletes the account and everything stored with it on the server, then signs out.
  Future<String?> deleteAccount() async {
    final session = _auth.currentSession;
    if (session == null) return 'You are not signed in.';
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}', 'apikey': Env.supabasePublishableKey},
      );
      if (response.status != 200) return 'Could not delete the account. Try again.';
    } catch (e) {
      debugPrint('Parley delete-account error: $e');
      return 'Could not delete the account. Check your connection and try again.';
    }
    await TaskStore.forget(session.user.id);
    await _auth.signOut(scope: SignOutScope.local);
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.busy) return;
    state = const AuthState(busy: true);
    try {
      await action();
      if (ref.mounted && state.busy) state = const AuthState();
    } on AuthException catch (e) {
      if (ref.mounted) state = AuthState(error: _friendly(e));
    } catch (e) {
      debugPrint('Parley auth error: $e');
      if (ref.mounted) state = const AuthState(error: 'Could not reach the server. Check your connection.');
    }
  }

  // Supabase error codes, turned into words a person can act on.
  String _friendly(AuthException e) => switch (e.code) {
        'invalid_credentials' => 'Wrong email or password.',
        'user_already_exists' || 'email_exists' => 'That email already has an account. Sign in instead.',
        'email_not_confirmed' => 'Confirm your email first. Check your inbox.',
        'weak_password' => 'Choose a stronger password.',
        'over_request_rate_limit' || 'over_email_send_rate_limit' => 'Too many tries. Wait a minute and try again.',
        _ => e.message,
      };
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
