// FILE: core/widgets/parley_mark.dart
// The Parley mark, drawn in code from the same geometry as brand/kit/parley-symbol.svg: two
// half-discs facing across a gap, the left one a step higher. Crisp at any size, and it follows
// light and dark mode through the theme colours. [ParleyMark.meet] below 1 draws the halves
// apart; [MeetingMark] plays them coming together once, for the welcome and sign-in screens.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';

class ParleyMark extends StatelessWidget {
  const ParleyMark({super.key, this.size = 40, this.meet = 1});
  final double size;

  /// 0: the halves apart and invisible. 1: the finished mark. Between, they slide in and fade up.
  final double meet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Parley',
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(
          // Light: green and mint. Dark: paper and mint, as in the dark lockup.
          left: dark ? colors.ink : colors.accent,
          right: ParleyColors.mint,
          meet: meet.clamp(0, 1),
        ),
      ),
    );
  }
}

/// The mark playing its meeting once when it first appears, then staying still. With reduce
/// motion on it is simply the finished mark.
class MeetingMark extends StatelessWidget {
  const MeetingMark({
    super.key,
    required this.size,
    this.duration = const Duration(milliseconds: 1000),
  });
  final double size;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0,
        end: 1,
      ),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, meet, _) => ParleyMark(size: size, meet: meet),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.left,
    required this.right,
    required this.meet,
  });
  final Color left;
  final Color right;
  final double meet;

  @override
  void paint(Canvas canvas, Size size) {
    // The brand grid is 256 units; both halves have radius 80.
    final unit = size.width / 256;
    Rect circle(double cx, double cy) => Rect.fromCircle(
      center: Offset(cx * unit, cy * unit),
      radius: 80 * unit,
    );
    final apart = (1 - meet) * 48;
    Paint fill(Color color) =>
        Paint()..color = color.withValues(alpha: color.a * meet);
    // Each half is a 180 degree sweep: the left one opens from the bottom, the right from the top.
    canvas
      ..drawArc(
        circle(120 - apart, 116),
        math.pi / 2,
        math.pi,
        true,
        fill(left),
      )
      ..drawArc(
        circle(136 + apart, 140),
        -math.pi / 2,
        math.pi,
        true,
        fill(right),
      );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.left != left || old.right != right || old.meet != meet;
}
