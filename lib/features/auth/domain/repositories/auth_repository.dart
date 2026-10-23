// FILE: features/auth/domain/repositories/auth_repository.dart
// What the app needs from an account system. The Supabase version is in
// data/repositories/auth_repository_impl.dart; tests can swap in a fake.
// Every method throws AppException with a message that is safe to show.

import '../entities/app_user.dart';

enum SignUpOutcome {
  /// The account exists and the user is signed in.
  signedIn,

  /// The project asks people to confirm their email before the first sign-in.
  confirmEmail,
}

abstract interface class AuthRepository {
  /// The signed-in user, then every change (sign in, sign out, account deleted).
  Stream<AppUser?> watchUser();

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  /// Creates the account with the person's name, which the app greets them by.
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  /// Changes the name on the signed-in account. The signed-in user updates with it.
  Future<void> updateName({
    required String firstName,
    required String lastName,
  });

  /// Signs out. `everywhere: false` only forgets the session on this phone, which never fails
  /// offline (used after deleting the account, when the server session is already gone).
  Future<void> signOut({bool everywhere = true});

  /// Deletes the account and its server data. Sign out afterwards.
  Future<void> deleteAccount();

  /// A valid session token for API calls. `fresh: true` forces a refresh.
  Future<String> accessToken({bool fresh = false});
}
