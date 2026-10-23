// FILE: core/session/account_cleanup.dart
// One local clean-up step to run after an account is deleted, given the deleted user's id.

typedef AccountCleanup = Future<void> Function(String userId);
