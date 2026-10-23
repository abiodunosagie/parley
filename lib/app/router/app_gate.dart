// FILE: app/router/app_gate.dart
// Which screen the app may show, in launch order: the launch animation first, then the welcome
// pages (once per install), then sign-in, then the app. One pure function, so every case is
// covered by test/app/app_gate_test.dart.

import 'app_routes.dart';

/// Where to send [location] instead, or null to stay.
String? gateRedirect({
  required String location,
  required bool launchDone,
  required bool onboardingSeen,
  required bool signedIn,
}) {
  String? only(String route) => location == route ? null : route;

  if (!launchDone) return only(AppRoutes.launch);
  if (!onboardingSeen) return only(AppRoutes.welcome);
  if (!signedIn) return only(AppRoutes.signIn);
  const entry = {AppRoutes.launch, AppRoutes.welcome, AppRoutes.signIn};
  return entry.contains(location) ? AppRoutes.chat : null;
}
