// FILE: features/conversation/presentation/widgets/greeting.dart
// The line Chat opens with: "Good morning, Ada." by the phone's clock, "Hello" in the small
// hours, and without a name when the account has none yet. Chat stays alive in its tab, so the
// intro reads the clock again whenever the app comes back to the front.

import 'package:flutter/widgets.dart';

import '../../../../core/widgets/screen_intro.dart';

const _morningFrom = 5;
const _afternoonFrom = 12;
const _eveningFrom = 17;
const _nightFrom = 23;

/// The greeting for [now] and [firstName] (empty when there is no name).
String greetingFor(DateTime now, String firstName) {
  final hour = now.hour;
  final part = hour >= _nightFrom || hour < _morningFrom
      ? 'Hello'
      : hour < _afternoonFrom
      ? 'Good morning'
      : hour < _eveningFrom
      ? 'Good afternoon'
      : 'Good evening';
  final name = firstName.trim();
  return name.isEmpty ? '$part.' : '$part, $name.';
}

/// Chat's intro, headed by the greeting for now.
class GreetingIntro extends StatefulWidget {
  const GreetingIntro({super.key, required this.firstName, required this.body});
  final String firstName;
  final String body;

  @override
  State<GreetingIntro> createState() => _GreetingIntroState();
}

class _GreetingIntroState extends State<GreetingIntro> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenIntro(
    title: greetingFor(DateTime.now(), widget.firstName),
    body: widget.body,
  );
}
