// FILE: features/rewrite/presentation/widgets/style_picker.dart
// The rewrite styles as a grid of square-cornered buttons (the selected one filled), plus the
// language picker when Translate is chosen.

import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/rewrite_style.dart';

class StylePicker extends StatelessWidget {
  const StylePicker({
    super.key,
    required this.style,
    required this.language,
    required this.onStyle,
    required this.onLanguage,
    this.enabled = true,
  });

  final RewriteStyle style;
  final String language;
  final ValueChanged<RewriteStyle> onStyle;
  final ValueChanged<String> onLanguage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in RewriteStyle.values)
              TextButton(
                onPressed: enabled ? () => onStyle(option) : null,
                style: TextButton.styleFrom(
                  backgroundColor: option == style
                      ? colors.accent
                      : colors.code,
                  foregroundColor: option == style
                      ? colors.onAccent
                      : colors.ink,
                  shape: const RoundedRectangleBorder(borderRadius: kRadius),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: Text(option.label),
              ),
          ],
        ),
        if (style == RewriteStyle.translate) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: const InputDecoration(labelText: 'Into'),
            items: [
              for (final l in rewriteLanguages)
                DropdownMenuItem(value: l, child: Text(l)),
            ],
            onChanged: enabled ? (l) => l == null ? null : onLanguage(l) : null,
          ),
        ],
      ],
    );
  }
}
