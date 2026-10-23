// FILE: features/auth/presentation/widgets/account_sheet.dart
// Who is signed in, Sign out, and Delete account (Apple requires in-app account deletion for any
// app with sign-up). Each step of the sheet is a state of AccountSheetController.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/parley_colors.dart';
import '../providers/account_sheet_controller.dart';
import '../providers/current_user_provider.dart';

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
    final email = ref.watch(currentUserProvider).value?.email ?? '';
    final text = Theme.of(context).textTheme;

    // While deleting, a tap outside the sheet does nothing; the delete always finishes first.
    return PopScope(
      canPop: state is! DeletingAccount,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SIGNED IN AS', style: text.labelSmall),
              const SizedBox(height: 4),
              Text(email, style: text.bodyLarge),
              const SizedBox(height: 20),
              ...switch (state) {
                AccountOverview() => _overview(context, controller),
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
    AccountSheetController controller,
  ) => [
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
