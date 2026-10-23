// FILE: features/auth/presentation/widgets/account_button.dart
// The person icon in every app bar. Opens the account sheet (account_sheet.dart).

import 'package:flutter/material.dart';

import 'account_sheet.dart';

class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const AccountSheet(),
      ),
    );
  }
}
