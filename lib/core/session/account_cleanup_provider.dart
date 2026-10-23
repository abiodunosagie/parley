// FILE: core/session/account_cleanup_provider.dart
// Local clean-up steps to run after an account is deleted (for example, removing that account's
// saved tasks from the phone). Features register their step in main.dart, so the auth feature can
// run them all without knowing which features exist.

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AccountCleanup = Future<void> Function(String userId);

final accountCleanupsProvider = Provider<List<AccountCleanup>>(
  (ref) => const [],
);
