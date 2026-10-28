// FILE: features/auth/presentation/widgets/account_sheet.dart
// Who is signed in (name and email, with a way to add or change the name), the user's own Claude
// key (add, replace or remove; see api_key_editor.dart), Sign out, and Delete
// account (Apple requires in-app account deletion for any app with sign-up). Each step of the
// sheet is a state of AccountSheetController.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/app_user.dart';
import '../providers/account_sheet_controller.dart';
import '../providers/current_user_provider.dart';
import 'api_key_editor.dart';
import 'name_editor.dart';

class AccountSheet extends ConsumerWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Close the sheet once the account is gone; the router then shows the sign-in screen.
    ref.listen(accountSheetControllerProvider, (_, next) {
      if (next is AccountDeleted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
    final state = ref.watch(accountSheetControllerProvider);
    final controller = ref.read(accountSheetControllerProvider.notifier);
    final user = ref.watch(currentUserProvider).value;
    final keyHint = ref.watch(savedApiKeyHintProvider);
    final text = Theme.of(context).textTheme;

    // While deleting, a tap outside the sheet does nothing; the delete always finishes first.
    return PopScope(
      canPop: state is! DeletingAccount,
      child: SafeArea(
        // Scrolls on a short phone or with large text while the keyboard is up.
        child: SingleChildScrollView(
          // Keeps the name boxes above the keyboard.
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SIGNED IN AS', style: text.labelSmall),
              const SizedBox(height: 4),
              if (user case AppUser(hasName: true, :final displayName))
                Text(displayName, style: text.titleMedium),
              Text(user?.email ?? '', style: text.bodyLarge),
              const SizedBox(height: 20),
              ...switch (state) {
                AccountOverview() => _overview(
                  context,
                  controller,
                  hasName: user?.hasName ?? false,
                  keyHint: keyHint,
                ),
                EditingName(:final saving, :final error) => [
                  NameEditor(
                    firstName: user?.firstName ?? '',
                    lastName: user?.lastName ?? '',
                    saving: saving,
                    error: error,
                    onSave: controller.saveName,
                    onCancel: controller.cancelEditName,
                  ),
                ],
                EditingApiKey(:final saving, :final error) => [
                  ApiKeyEditor(
                    saving: saving,
                    error: error,
                    onSave: controller.saveApiKey,
                    onCancel: controller.cancelEditApiKey,
                  ),
                ],
                ConfirmingDelete(:final error) => _confirm(
                  context,
                  controller,
                  error: error,
                  deleting: false,
                ),
                DeletingAccount() || AccountDeleted() => _confirm(
                  context,
                  controller,
                  deleting: true,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _overview(
    BuildContext context,
    AccountSheetController controller, {
    required bool hasName,
    required AsyncValue<String?> keyHint,
  }) => [
    OutlinedButton(
      onPressed: controller.editName,
      child: Text(hasName ? 'Change name' : 'Add your name'),
    ),
    const SizedBox(height: 20),
    ..._apiKey(context, controller, keyHint),
    const SizedBox(height: 20),
    OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
        controller.signOut();
      },
      child: const Text('Sign out'),
    ),
    const SizedBox(height: 10),
    TextButton(
      onPressed: controller.askToDelete,
      style: TextButton.styleFrom(
        foregroundColor: context.colors.danger,
        minimumSize: const Size.fromHeight(48),
      ),
      child: const Text('Delete account'),
    ),
  ];

  /// Which key pays for requests, and the buttons to change it.
  List<Widget> _apiKey(
    BuildContext context,
    AccountSheetController controller,
    AsyncValue<String?> saved,
  ) {
    final text = Theme.of(context).textTheme;
    // Until secure storage answers, say nothing rather than claim there is no key.
    if (saved.isLoading) {
      return [Text('CLAUDE API KEY', style: text.labelSmall)];
    }
    // A key that cannot be read is offered for replacing or removing, like a saved one.
    final keyHint = saved.hasError ? 'unreadable' : saved.value;
    return [
      Text('CLAUDE API KEY', style: text.labelSmall),
      const SizedBox(height: 4),
      Text(
        saved.hasError
            ? 'Your saved key could not be read. Replace it or remove it.'
            : keyHint == null
            ? "Parley's shared key, with daily limits."
            : 'Your own key, $keyHint. Kept only on this phone.',
        style: text.bodyMedium,
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: controller.editApiKey,
        child: Text(keyHint == null ? 'Use your own key' : 'Replace key'),
      ),
      if (keyHint != null) ...[
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.removeApiKey,
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Remove my key'),
        ),
      ],
    ];
  }

  List<Widget> _confirm(
    BuildContext context,
    AccountSheetController controller, {
    required bool deleting,
    String? error,
  }) {
    final colors = context.colors;
    return [
      Text(
        'This deletes your Parley account and its usage history for good. '
        'Tasks saved on this phone are removed too. This cannot be undone.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(error, style: TextStyle(color: colors.danger)),
        ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: deleting ? null : controller.deleteAccount,
        style: FilledButton.styleFrom(
          backgroundColor: colors.danger,
          foregroundColor: colors.background,
        ),
        child: Text(deleting ? 'Deleting...' : 'Delete my account'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: deleting ? null : controller.keepAccount,
        child: const Text('Keep my account'),
      ),
    ];
  }
}
