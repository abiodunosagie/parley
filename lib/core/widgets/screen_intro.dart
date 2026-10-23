// FILE: core/widgets/screen_intro.dart
// The headline and one line of explanation at the top of an empty screen.

import 'package:flutter/material.dart';

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
