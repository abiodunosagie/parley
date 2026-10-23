// FILE: features/auth/data/repositories/auth_repository_impl.dart
// The Supabase version of AuthRepository: email and password accounts, the person's name (kept in
// the account's user metadata), session refresh, and account deletion through the
// `delete-account` edge function. Passwords go straight to Supabase
// over HTTPS; the app never stores them. Every Supabase error becomes an AppException with words
// a person can act on.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/session/account_cleanup_provider.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/delete_account.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);
  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static const _firstName = 'first_name';
  static const _lastName = 'last_name';

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    String meta(String key) {
      final value = user.userMetadata?[key];
      return value is String ? value.trim() : '';
    }

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      firstName: meta(_firstName),
      lastName: meta(_lastName),
    );
  }

  @override
  Stream<AppUser?> watchUser() =>
      _auth.onAuthStateChange.map((event) => _toAppUser(event.session?.user));

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithPassword(email: email.trim(), password: password),
      );

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) => _guard(() async {
    final result = await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {_firstName: firstName, _lastName: lastName},
    );
    return result.session == null
        ? SignUpOutcome.confirmEmail
        : SignUpOutcome.signedIn;
  });

  @override
  Future<void> updateName({
    required String firstName,
    required String lastName,
  }) => _guard(
    () => _auth.updateUser(
      UserAttributes(data: {_firstName: firstName, _lastName: lastName}),
    ),
  );

  @override
  Future<void> signOut({bool everywhere = true}) async {
    if (everywhere) return _auth.signOut();
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('Parley local sign-out: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.functions.invoke(
        'delete-account',
        headers: {
          'Authorization': 'Bearer ${await accessToken()}',
          'apikey': Env.supabasePublishableKey,
        },
      );
    } on FunctionException catch (e) {
      debugPrint('Parley delete-account refused: ${e.status}');
      throw AppException(
        e.status == 401
            ? 'Your session ended. Sign in again, then delete the account.'
            : 'Could not delete the account. Try again.',
      );
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('Parley delete-account error: $e');
      throw const AppException(
        'Could not delete the account. Check your connection and try again.',
      );
    }
  }

  @override
  Future<String> accessToken({bool fresh = false}) async {
    var session = _auth.currentSession;
    if (session == null) throw const AppException('Sign in to use Parley.');
    if (fresh || session.isExpired) {
      try {
        session = (await _auth.refreshSession()).session;
      } on AuthRetryableFetchException {
        // Offline or a server blip: keep the session and let the user try again.
        throw const AppException(
          'No connection. Check your internet and try again.',
        );
      } on AuthException {
        // The refresh token itself was refused, so this session is over for good.
        await _auth.signOut(scope: SignOutScope.local);
        throw const AppException('Your session ended. Sign in again.');
      }
    }
    return session?.accessToken ??
        (throw const AppException('Sign in to use Parley.'));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw AppException(_friendly(e));
    } catch (e) {
      debugPrint('Parley auth error: $e');
      throw const AppException(
        'Could not reach the server. Check your connection.',
      );
    }
  }

  // Supabase error codes, turned into words a person can act on.
  static String _friendly(AuthException e) => switch (e.code) {
    'invalid_credentials' => 'Wrong email or password.',
    'user_already_exists' ||
    'email_exists' => 'That email already has an account. Sign in instead.',
    'email_not_confirmed' => 'Confirm your email first. Check your inbox.',
    'weak_password' => 'Choose a stronger password.',
    'over_request_rate_limit' || 'over_email_send_rate_limit' =>
      'Too many tries. Wait a minute and try again.',
    _ =>
      e is AuthRetryableFetchException
          ? 'Could not reach the server. Check your connection.'
          : 'That did not work. Check your details and try again.',
  };
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(supabaseClientProvider)),
);

final deleteAccountProvider = Provider<DeleteAccount>(
  (ref) => DeleteAccount(
    repository: ref.watch(authRepositoryProvider),
    cleanups: ref.watch(accountCleanupsProvider),
  ),
);
