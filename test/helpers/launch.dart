// Steps a test past the launch splash. The splash runs on timers (a grace after the first frame,
// the animation, then a hold), so the clock has to be moved on; settling frames alone returns
// while the splash is still up. Shared by the widget tests and the integration tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:parley/app/launch/launch_screen.dart';

Future<void> pumpPastLaunch(WidgetTester tester) async {
  const step = Duration(milliseconds: 250);
  // One extra step covers the first frame itself.
  final steps = LaunchScreen.total.inMilliseconds ~/ step.inMilliseconds + 2;
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
  await tester.pumpAndSettle();
}
