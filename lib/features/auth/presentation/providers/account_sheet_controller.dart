// FILE: features/auth/presentation/providers/account_sheet_controller.dart
// The account sheet's steps: the overview (name, email, sign out), editing the name, the delete
// confirmation, deleting, and a failed delete. A fresh controller is made each time the sheet
// opens (autoDispose).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/validators/auth_validators.dart';

sealed class AccountSheetState {
  const AccountSheetState();
}

class AccountOverview extends AccountSheetState {
  const AccountOverview();
}

/// Changing the name. [error] is why the last save failed.
class EditingName extends AccountSheetState {
  const EditingName({this.saving = false, this.error});
  final bool saving;
  final String? error;
}

class ConfirmingDelete extends AccountSheetState {
  const ConfirmingDelete({this.error});

  /// Set when the last delete attempt failed, so the user can read why and try again.
  final String? error;
}

class DeletingAccount extends AccountSheetState {
  const DeletingAccount();
}

class AccountDeleted extends AccountSheetState {
  const AccountDeleted();
}

class AccountSheetController extends Notifier<AccountSheetState> {
  @override
  AccountSheetState build() => const AccountOverview();

  void askToDelete() => state = const ConfirmingDelete();

  void keepAccount() => state = const AccountOverview();

  void editName() => state = const EditingName();

  void cancelEditName() => state = const AccountOverview();

  /// Saves the name (already validated by the form). The signed-in user updates by itself, so
  /// the greeting and this sheet show the new name straight away.
  Future<void> saveName({
    required String firstName,
    required String lastName,
  }) async {
    if (state case EditingName(saving: true)) return;
    state = const EditingName(saving: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateName(
            firstName: cleanName(firstName),
            lastName: cleanName(lastName),
          );
      if (ref.mounted) state = const AccountOverview();
    } catch (e) {
      if (ref.mounted) {
        state = EditingName(
          error: reportError(e, cancelled: false, tag: 'name'),
        );
      }
    }
  }

  /// Signs out everywhere; if the server cannot be reached, forgets the session on this phone
  /// so the button always does what it says.
  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.signOut();
    } catch (e) {
      reportError(e, cancelled: false, tag: 'sign-out');
      await repository.signOut(everywhere: false);
    }
  }

  Future<void> deleteAccount() async {
    if (state is DeletingAccount) return;
    // Read everything before the first await: if the sheet closes meanwhile, this controller is
    // disposed and `ref` can no longer be used, but the delete must still finish.
    final deleteAccount = ref.read(deleteAccountProvider);
    state = const DeletingAccount();
    try {
      final cleanupFailures = await deleteAccount();
      for (final failure in cleanupFailures) {
        reportError(failure, cancelled: false, tag: 'account clean-up');
      }
      if (ref.mounted) state = const AccountDeleted();
    } catch (e) {
      if (ref.mounted) {
        state = ConfirmingDelete(
          error: reportError(e, cancelled: false, tag: 'delete-account'),
        );
      }
    }
  }
}

final accountSheetControllerProvider =
    NotifierProvider.autoDispose<AccountSheetController, AccountSheetState>(
      AccountSheetController.new,
    );
