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

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
    with SingleTickerProviderStateMixin {
  // 0 to 0.65: the halves meet. 0.5 to 0.9: the name fades up. Then a short hold on the
  // finished mark before moving on.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _meet = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
  );
  late final _name = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
  );
  Timer? _hold;
  var _started = false;

  static const _holdFinished = Duration(milliseconds: 450);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _hold = Timer(const Duration(milliseconds: 700), _finish);
      return;
    }
    // The first frames of a cold start are slow (the engine is still warming up). Starting the
    // clock now would spend most of the animation before anything is on screen, so it starts
    // once the first frame has really been drawn, plus a breath.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hold = Timer(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _controller.forward().whenComplete(() {
          _hold = Timer(_holdFinished, _finish);
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
    _meet.dispose();
    _name.dispose();
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
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ParleyMark(size: 112, meet: _meet.value),
              const SizedBox(height: 18),
              Opacity(
                opacity: _name.value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - _name.value)),
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
          ),
        ),
      ),
    );
  }
}
