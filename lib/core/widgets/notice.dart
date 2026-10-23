// FILE: core/widgets/notice.dart
// A one-line message in the danger colour under the content: an error, or why Claude stopped early.

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';

/// A one-line message under the content: an error, or why Claude stopped early.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final danger = context.colors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
  }
}
