import 'package:flutter_test/flutter_test.dart';
import 'package:parley/app/router/app_gate.dart';
import 'package:parley/app/router/app_routes.dart';

String? gate(
  String location, {
  bool launchDone = true,
  bool onboardingSeen = true,
  bool signedIn = true,
}) => gateRedirect(
  location: location,
  launchDone: launchDone,
  onboardingSeen: onboardingSeen,
  signedIn: signedIn,
);

void main() {
  test('the launch animation comes first, whatever else is true', () {
    expect(gate(AppRoutes.chat, launchDone: false), AppRoutes.launch);
    expect(gate(AppRoutes.launch, launchDone: false), isNull);
  });

  test('a fresh install sees the welcome pages before sign-in', () {
    expect(
      gate(AppRoutes.launch, onboardingSeen: false, signedIn: false),
      AppRoutes.welcome,
    );
    expect(
      gate(AppRoutes.welcome, onboardingSeen: false, signedIn: false),
      isNull,
    );
    expect(
      gate(AppRoutes.signIn, onboardingSeen: false, signedIn: false),
      AppRoutes.welcome,
    );
  });

  test('after the welcome pages, signed-out people go to sign-in', () {
    expect(gate(AppRoutes.welcome, signedIn: false), AppRoutes.signIn);
    expect(gate(AppRoutes.launch, signedIn: false), AppRoutes.signIn);
    expect(gate(AppRoutes.tasks, signedIn: false), AppRoutes.signIn);
    expect(gate(AppRoutes.signIn, signedIn: false), isNull);
  });

  test('signed-in people skip launch, welcome and sign-in, and stay where they are otherwise', () {
    for (final entry in [
      AppRoutes.launch,
      AppRoutes.welcome,
      AppRoutes.signIn,
    ]) {
      expect(gate(entry), AppRoutes.chat, reason: entry);
    }
    expect(gate(AppRoutes.tasks), isNull);
    expect(gate(AppRoutes.rewrite), isNull);
  });
}
