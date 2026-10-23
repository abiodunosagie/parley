// FILE: core/widgets/keyboard_dismiss.dart
// Closes the keyboard when you tap anywhere that is not a text field, like WhatsApp and
// Messenger. Wrapped around every screen in app.dart. Taps on buttons and fields still reach
// them first (test/core/widgets/keyboard_dismiss_test.dart proves it).

import 'package:flutter/material.dart';

class KeyboardDismiss extends StatelessWidget {
  const KeyboardDismiss({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
