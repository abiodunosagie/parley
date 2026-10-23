// FILE: features/auth/presentation/widgets/submit_button.dart
// A full-width primary button that shows a small spinner while its action runs.

import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
