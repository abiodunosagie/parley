// FILE: features/conversation/presentation/widgets/typing_dots.dart
// Three dots that pulse in turn while Claude is thinking, like "typing..." in a messaging app.

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

/// Three dots that pulse in turn while Claude is thinking, like the "typing..." indicator in a
/// messaging app.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.muted;
    return Semantics(
      label: 'Parley is thinking',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Opacity(
                  // Each dot peaks a third of a cycle after the one before it.
                  opacity:
                      0.3 + 0.7 * _pulse((_controller.value - i * 0.2) % 1),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 0 to 1 and back to 0 over the first half of the cycle, then rests at 0.
  double _pulse(double t) => t < 0.5 ? 1 - (2 * t - 0.5).abs() * 2 : 0;
}
