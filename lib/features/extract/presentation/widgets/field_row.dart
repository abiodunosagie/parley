// FILE: features/extract/presentation/widgets/field_row.dart
// One extracted field: a small caps label over the value, with a hairline under it.
// Empty values read "Not stated" instead of leaving a blank row.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? 'Not stated' : value,
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}
