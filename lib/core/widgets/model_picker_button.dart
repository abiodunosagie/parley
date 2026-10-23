// FILE: core/widgets/model_picker_button.dart
// The "Opus 5.5" button in the app bar. Opens a sheet to switch between Haiku, Sonnet and Opus.
// The choice is stored in selectedModelProvider (core/state/selected_model_provider.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claude_model.dart';
import '../state/selected_model_provider.dart';
import '../theme/parley_colors.dart';

/// App bar button that shows the current model and opens a sheet to switch it.
class ModelPickerButton extends ConsumerWidget {
  const ModelPickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(selectedModelProvider);
    return TextButton.icon(
      onPressed: () => _open(context, ref),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.expand_more, size: 20),
      label: Text(model.label),
      style: TextButton.styleFrom(foregroundColor: context.colors.ink),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current = ref.read(selectedModelProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: RadioGroup<ClaudeModel>(
              groupValue: current,
              onChanged: (model) {
                if (model != null) {
                  ref.read(selectedModelProvider.notifier).select(model);
                }
                Navigator.pop(sheetContext);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final model in ClaudeModel.values)
                    RadioListTile<ClaudeModel>(
                      value: model,
                      title: Text(model.label),
                      subtitle: Text(model.blurb),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
