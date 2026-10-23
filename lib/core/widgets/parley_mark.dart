// FILE: core/widgets/parley_mark.dart
// The Parley mark, drawn in code from the same geometry as brand/kit/parley-symbol.svg: two
// half-discs facing across a gap, the left one a step higher. Crisp at any size, and it follows
// light and dark mode through the theme colours.

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';

class ParleyMark extends StatelessWidget {
  const ParleyMark({super.key, this.size = 40});
  final double size;

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
          right: dark ? colors.accent : const Color(0xFF5CC79C),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.left, required this.right});
  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    // The brand grid is 256 units; both halves have radius 80.
    final unit = size.width / 256;
    Rect circle(double cx, double cy) => Rect.fromCircle(
      center: Offset(cx * unit, cy * unit),
      radius: 80 * unit,
    );
    const half = 3.141592653589793;
    canvas
      ..drawArc(circle(120, 116), half / 2, half, true, Paint()..color = left)
      ..drawArc(
        circle(136, 140),
        -half / 2,
        half,
        true,
        Paint()..color = right,
      );
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.left != left || old.right != right;
}
