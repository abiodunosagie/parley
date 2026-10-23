import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The headline and one line of explanation at the top of an empty screen.
class ScreenIntro extends StatelessWidget {
  const ScreenIntro({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );
  }
}

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
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(14)),
              child: Text(item),
            ),
          ),
      ],
    );
  }
}

/// What the user said, right-aligned in a tinted block.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: context.colors.userBubble, borderRadius: kRadius),
        child: child,
      ),
    );
  }
}

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
          Expanded(child: Text(text, style: TextStyle(color: danger))),
        ],
      ),
    );
  }
}
