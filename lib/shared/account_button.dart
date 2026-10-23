// FILE: shared/account_button.dart
// The person icon in the app bar: shows the signed-in email, Sign out, and Delete
// account (Apple requires in-app account deletion for any app with sign-up).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../features/auth/auth_controller.dart';

/// App bar button that opens the account sheet: who is signed in, sign out, delete account.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _AccountSheet(),
      ),
    );
  }
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet();

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  var _confirmingDelete = false;
  var _deleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final error = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount();
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _deleting = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final email = ref.watch(currentUserProvider).value?.email ?? '';
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SIGNED IN AS', style: text.labelSmall),
            const SizedBox(height: 4),
            Text(email, style: text.bodyLarge),
            const SizedBox(height: 20),
            if (!_confirmingDelete) ...[
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).signOut();
                },
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _confirmingDelete = true),
                style: TextButton.styleFrom(
                  foregroundColor: colors.danger,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Delete account'),
              ),
            ] else ...[
              Text(
                'This deletes your Parley account and its usage history for good. '
                'Tasks saved on this phone are removed too. This cannot be undone.',
                style: text.bodyMedium,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: colors.danger)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _deleting ? null : _delete,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: colors.background,
                ),
                child: Text(_deleting ? 'Deleting...' : 'Delete my account'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _deleting
                    ? null
                    : () => setState(() => _confirmingDelete = false),
                child: const Text('Keep my account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
