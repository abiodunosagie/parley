// FILE: app/launch/launch_screen.dart
// The splash after the native launch screen, on the same background so the hand-off cannot be
// seen: the two halves of the mark slide in and meet, the name fades up, a short beat, then the
// router moves on (onboarding, sign-in or the app). Plays once, never loops. With reduce motion
// on it shows the finished mark briefly instead.

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
  // 0 to 0.6: the halves meet. 0.45 to 0.8: the name fades up. Then a beat before moving on.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final _meet = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
  );
  late final _name = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
  );
  Timer? _hold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _hold = Timer(const Duration(milliseconds: 500), _finish);
    } else {
      _controller.forward().whenComplete(_finish);
    }
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
