// FILE: core/widgets/voice_wave.dart
// The live waveform while you dictate: bars that rise and fall with your voice, moving even in
// quiet moments so it is clear Parley is listening.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/parley_colors.dart';

class VoiceWave extends StatefulWidget {
  const VoiceWave({
    super.key,
    required this.level,
    this.bars = 7,
    this.height = 28,
  });

  /// How loud you are, 0 to 1.
  final double level;
  final int bars;
  final double height;

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave>
    with SingleTickerProviderStateMixin {
  late final _ticker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  /// The level eased towards the latest reading, so the bars glide instead of jumping.
  double _smooth = 0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.accent;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        _smooth += (widget.level - _smooth) * 0.25;
        final t = reduceMotion ? 0.0 : _ticker.value * 2 * math.pi;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.bars; i++)
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height:
                      widget.height *
                      (0.18 +
                          0.82 *
                              (0.25 + 0.75 * _smooth) *
                              (0.5 + 0.5 * math.sin(t + i * 0.9))),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
