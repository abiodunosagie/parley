// FILE: app/router/app_gate.dart
// Which screen the app may show, in launch order: the launch animation first, then the welcome
// pages (once per install, and only for someone signed out: a person already signed in from an
// older version goes straight to the app), then sign-in, then the app. One pure function, so
// every case is covered by test/app/app_gate_test.dart.

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
  if (!signedIn) {
    return only(onboardingSeen ? AppRoutes.signIn : AppRoutes.welcome);
  }
  const entry = {AppRoutes.launch, AppRoutes.welcome, AppRoutes.signIn};
  return entry.contains(location) ? AppRoutes.chat : null;
}
