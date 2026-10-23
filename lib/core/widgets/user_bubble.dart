// FILE: core/widgets/user_bubble.dart
// What the user said, right-aligned in a tinted block. Used by Chat, Look and Tasks.

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';
import '../theme/dimens.dart';

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
        decoration: BoxDecoration(
          color: context.colors.userBubble,
          borderRadius: kRadius,
        ),
        child: child,
      ),
    );
  }
}
