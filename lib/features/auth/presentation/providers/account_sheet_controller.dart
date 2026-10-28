// FILE: features/auth/presentation/providers/account_sheet_controller.dart
// The account sheet's steps: the overview (name, email, own Claude key, sign out), editing the
// name, adding the user's own Claude key, the delete confirmation, deleting, and a failed delete.
// A fresh controller is made each time the sheet opens (autoDispose).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../data/repositories/api_key_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/validators/auth_validators.dart';
import 'current_user_provider.dart';

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

/// Adding or replacing the user's own Claude key. [error] is why the last save failed.
class EditingApiKey extends AccountSheetState {
  const EditingApiKey({this.saving = false, this.error});
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

  void editApiKey() => state = const EditingApiKey();

  void cancelEditApiKey() => state = const AccountOverview();

  /// Saves the user's own key (already validated by the form) for the signed-in account. Every
  /// request after this one is paid for with it.
  Future<void> saveApiKey(String key) async {
    if (state case EditingApiKey(saving: true)) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = const EditingApiKey(saving: true);
    try {
      await ref.read(apiKeyRepositoryProvider).save(userId, cleanApiKey(key));
      // The sheet may have been swiped away while saving; the key is saved either way.
      if (!ref.mounted) return;
      ref.invalidate(savedApiKeyHintProvider);
      state = const AccountOverview();
    } catch (e) {
      if (ref.mounted) {
        state = EditingApiKey(
          error: reportError(e, cancelled: false, tag: 'api key'),
        );
      }
    }
  }

  /// Forgets the user's own key; requests go back to Parley's shared key and its daily limits.
  Future<void> removeApiKey() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      await ref.read(apiKeyRepositoryProvider).remove(userId);
    } catch (e) {
      // The hint is read again from storage below, so a failed removal still shows the key and
      // the user can try again.
      reportError(e, cancelled: false, tag: 'api key');
    }
    if (ref.mounted) ref.invalidate(savedApiKeyHintProvider);
  }

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

/// The saved own key, masked ("sk-ant-...x7Qa"), or null when the account has none.
final savedApiKeyHintProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final key = await ref.watch(apiKeyRepositoryProvider).read(userId);
  return key == null ? null : maskApiKey(key);
});
