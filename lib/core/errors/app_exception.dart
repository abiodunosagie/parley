// FILE: core/errors/app_exception.dart
// An error whose message is safe to show on screen as is. The server and the repositories only
// ever put plain words in it, never stack traces or internal details.

class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}
