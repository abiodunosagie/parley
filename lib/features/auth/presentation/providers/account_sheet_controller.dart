// FILE: features/auth/presentation/providers/account_sheet_controller.dart
// The account sheet's steps: the overview (email, sign out), the delete confirmation, deleting,
// and a failed delete. A fresh controller is made each time the sheet opens (autoDispose).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/user_messages.dart';
import '../../../../core/session/account_cleanup_provider.dart';
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

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<void> deleteAccount() async {
    if (state is DeletingAccount) return;
    final repository = ref.read(authRepositoryProvider);
    final userId = repository.currentUser?.id;
    if (userId == null) return;
    state = const DeletingAccount();
    try {
      await repository.deleteAccount();
      // Clean up before signing out: signing out closes this sheet and disposes this controller.
      for (final cleanup in ref.read(accountCleanupsProvider)) {
        await cleanup(userId);
      }
      if (ref.mounted) state = const AccountDeleted();
      await repository.signOut(everywhere: false);
    } catch (e) {
      if (ref.mounted) {
        state = ConfirmingDelete(
          error: messageFor(e, cancelled: false, tag: 'delete-account'),
        );
      }
    }
  }
}

final accountSheetControllerProvider =
    NotifierProvider.autoDispose<AccountSheetController, AccountSheetState>(
      AccountSheetController.new,
    );
