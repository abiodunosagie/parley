// FILE: features/auth/presentation/providers/account_sheet_controller.dart
// The account sheet's steps: the overview (email, sign out), the delete confirmation, deleting,
// and a failed delete. A fresh controller is made each time the sheet opens (autoDispose).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../data/repositories/auth_repository_impl.dart';

sealed class AccountSheetState {
  const AccountSheetState();
}

class AccountOverview extends AccountSheetState {
  const AccountOverview();
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
