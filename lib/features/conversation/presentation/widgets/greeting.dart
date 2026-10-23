// FILE: features/conversation/presentation/widgets/greeting.dart
// The line Chat opens with: "Good morning, Ada." by the phone's clock, or without a name when the
// account has none yet.

/// The greeting for [now] and [firstName] (empty when there is no name).
String greetingFor(DateTime now, String firstName) {
  final hour = now.hour;
  final part = hour >= 5 && hour < 12
      ? 'Good morning'
      : hour >= 12 && hour < 17
      ? 'Good afternoon'
      : 'Good evening';
  final name = firstName.trim();
  return name.isEmpty ? '$part.' : '$part, $name.';
}
