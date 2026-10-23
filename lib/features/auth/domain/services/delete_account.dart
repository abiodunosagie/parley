// FILE: features/auth/domain/services/delete_account.dart
// Deleting an account, start to finish: delete it on the server, run every feature's local
// clean-up (for example the saved tasks), then forget the session on this phone. Kept out of the
// UI so it always completes, even if the sheet that started it is closed halfway.

import '../../../../core/session/account_cleanup.dart';
import '../repositories/auth_repository.dart';

class DeleteAccount {
  const DeleteAccount({required this.repository, required this.cleanups});
  final AuthRepository repository;
  final List<AccountCleanup> cleanups;

  /// Throws AppException when the server delete fails (nothing else has happened then).
  /// After a successful delete, clean-up failures are returned instead of thrown: the account is
  /// already gone, so the user is signed out either way.
  Future<List<Object>> call() async {
    final userId = repository.currentUser?.id;
    if (userId == null) return const [];
    await repository.deleteAccount();
    final failures = <Object>[];
    for (final cleanup in cleanups) {
      try {
        await cleanup(userId);
      } catch (e) {
        failures.add(e);
      }
    }
    await repository.signOut(everywhere: false);
    return failures;
  }
}
