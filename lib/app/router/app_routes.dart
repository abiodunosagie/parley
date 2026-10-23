// FILE: app/router/app_routes.dart
// Every route path in one place, so no widget types a path by hand.

abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const chat = '/chat';
  static const look = '/look';
  static const read = '/read';
  static const tasks = '/tasks';
  static const tools = '/tools';

  // Under Tools, each pushed on top of the tools list (relative paths for GoRoute).
  static const extractPath = 'extract';
  static const receiptsPath = 'receipts';
  static const rewritePath = 'rewrite';
  static const extract = '$tools/$extractPath';
  static const receipts = '$tools/$receiptsPath';
  static const rewrite = '$tools/$rewritePath';
}
