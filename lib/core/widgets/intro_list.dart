// FILE: core/widgets/intro_list.dart
// An empty screen's content as a scrollable column (so it never overflows when the keyboard is
// up): optional content on top, then tap-to-send starters.

import 'package:flutter/material.dart';

import 'starter_buttons.dart';

class IntroList extends StatelessWidget {
  const IntroList({
    super.key,
    required this.header,
    required this.starters,
    required this.onPick,
  });
  final Widget header;
  final List<String> starters;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      children: [
        header,
        StarterButtons(items: starters, onPick: onPick),
      ],
    );
  }
}
