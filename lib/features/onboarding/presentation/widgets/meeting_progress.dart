// FILE: features/onboarding/presentation/widgets/meeting_progress.dart
// The welcome pages' progress, drawn with the brand mark itself: the two halves start at the
// edges of the screen and move closer with every page, until on the last page they meet and
// become the Parley mark. It replaces page dots, and says what the app is: two sides meeting.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';

class MeetingProgress extends StatelessWidget {
  const MeetingProgress({
    super.key,
    required this.progress,
    this.size = 132,
    this.height,
  });

  /// 0 on the first page, 1 on the last.
  final double progress;

  /// The finished mark's size when the halves meet.
  final double size;

  /// The space the halves sit in, centred vertically. Defaults to [size].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Step ${(progress * 3).round() + 1} of 4',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, p, _) => CustomPaint(
          size: Size(double.infinity, height ?? size),
          painter: _HalvesPainter(
            progress: p,
            mark: size,
            left: dark ? colors.ink : colors.accent,
            right: dark ? colors.accent : const Color(0xFF5CC79C),
          ),
        ),
      ),
    );
  }
}

class _HalvesPainter extends CustomPainter {
  const _HalvesPainter({
    required this.progress,
    required this.mark,
    required this.left,
    required this.right,
  });

  final double progress;
  final double mark;
  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    // The brand grid: 256 units, radius 80, gap 16, the left half 24 units higher.
    final unit = mark / 256;
    final radius = 80 * unit;
    final centreX = size.width / 2;
    final top = (size.height - mark) / 2;
    // Where each flat edge sits when the halves meet, and how far out they start: near the
    // screen edges, with most of each half in view.
    final meetLeft = centreX - 8 * unit;
    final meetRight = centreX + 8 * unit;
    final apart = 1 - progress;
    final leftEdge = meetLeft - apart * (meetLeft - radius * 0.8);
    final rightEdge =
        meetRight + apart * (size.width - radius * 0.8 - meetRight);

    Rect circle(double edgeX, double cy) =>
        Rect.fromCircle(center: Offset(edgeX, top + cy * unit), radius: radius);
    canvas
      ..drawArc(
        circle(leftEdge, 116),
        math.pi / 2,
        math.pi,
        true,
        Paint()..color = left,
      )
      ..drawArc(
        circle(rightEdge, 140),
        -math.pi / 2,
        math.pi,
        true,
        Paint()..color = right,
      );
  }

  @override
  bool shouldRepaint(_HalvesPainter old) =>
      old.progress != progress ||
      old.left != left ||
      old.right != right ||
      old.mark != mark;
}
