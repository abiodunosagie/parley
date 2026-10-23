// FILE: core/widgets/starter_buttons.dart
// Example prompts on an empty screen, drawn as messages you have not sent yet: on the right like
// your own bubbles, outlined instead of filled, each with the send arrow. Tap one and it becomes
// your first turn.

import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/parley_colors.dart';

class StarterButtons extends StatelessWidget {
  const StarterButtons({super.key, required this.items, required this.onPick});
  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 40),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: kRadius,
                side: BorderSide(color: colors.userBubble, width: 1.5),
              ),
              child: InkWell(
                borderRadius: kRadius,
                onTap: () => onPick(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: colors.accent,
                        semanticLabel: 'Send',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
