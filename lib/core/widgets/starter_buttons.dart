// FILE: core/widgets/starter_buttons.dart
// Tap-to-send example prompts, one full-width row each.

import 'package:flutter/material.dart';

/// Tap-to-send example prompts, one full-width row each.
class StarterButtons extends StatelessWidget {
  const StarterButtons({super.key, required this.items, required this.onPick});
  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => onPick(item),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
              ),
              child: Text(item),
            ),
          ),
      ],
    );
  }
}
