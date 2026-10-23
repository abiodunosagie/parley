// FILE: app/launch/launch_screen.dart
// The splash after the native launch screen, on the same background so the hand-off cannot be
// seen: the two halves of the mark slide in and meet, the name fades up, the finished mark holds
// for a moment, then the router moves on (onboarding, sign-in or the app). Plays once, never
// loops, and only starts once the first frame is on screen so none of it is lost to a slow cold
// start. With reduce motion on it shows the finished mark briefly instead.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/parley_colors.dart';
import '../../core/widgets/parley_mark.dart';
import 'launch_controller.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  /// The wait after the first frame before the animation starts.
  static const firstFrameGrace = Duration(milliseconds: 120);

  /// The animation itself.
  static const play = Duration(milliseconds: 1600);

  /// How long the finished mark stays before the router moves on.
  static const holdFinished = Duration(milliseconds: 450);

  /// With reduce motion on: how long the finished mark shows instead.
  static const reducedMotionHold = Duration(milliseconds: 700);

  /// The whole splash, start to hand-over, for tests that need to step past it.
  static Duration get total => firstFrameGrace + play + holdFinished;

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LaunchScreen.play,
  );
  Timer? _hold;
  var _started = false;

  // On the one clock: 0 to 0.65 the halves meet, 0.5 to 0.9 the name fades up. The name is not a
  // separate Reveal because that would start its own clock before the first frame.
  static const _meet = Interval(0, 0.65, curve: Curves.easeOutCubic);
  static const _name = Interval(0.5, 0.9, curve: Curves.easeOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _hold = Timer(LaunchScreen.reducedMotionHold, _finish);
      return;
    }
    // The first frames of a cold start are slow (the engine is still warming up). Starting the
    // clock now would spend most of the animation before anything is on screen, so it starts
    // once the first frame has really been drawn, plus a breath.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hold = Timer(LaunchScreen.firstFrameGrace, () {
        if (!mounted) return;
        _controller.forward().whenComplete(() {
          if (mounted) _hold = Timer(LaunchScreen.holdFinished, _finish);
        });
      });
    });
  }

  void _finish() {
    if (mounted) ref.read(launchDoneProvider.notifier).done();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final name = _name.transform(_controller.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParleyMark(size: 112, meet: _meet.transform(_controller.value)),
                const SizedBox(height: 18),
                Opacity(
                  opacity: name,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - name)),
                    child: Text(
                      'parley',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
