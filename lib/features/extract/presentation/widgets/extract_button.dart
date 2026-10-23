// FILE: features/extract/presentation/widgets/extract_button.dart
// "Extract fields", which turns into "Reading... tap to stop" while the request runs.

import 'package:flutter/material.dart';

class ExtractButton extends StatelessWidget {
  const ExtractButton({
    super.key,
    required this.busy,
    required this.onExtract,
    required this.onStop,
  });
  final bool busy;
  final VoidCallback onExtract;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (!busy) {
      return FilledButton(
        onPressed: onExtract,
        child: const Text('Extract fields'),
      );
    }
    return OutlinedButton.icon(
      onPressed: onStop,
      icon: const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: const Text('Reading... tap to stop'),
    );
  }
}
