// FILE: features/rewrite/presentation/providers/rewrite_history_provider.dart
// The signed-in account's saved rewrites, newest first.

import '../../../../core/state/saved_history.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/rewrite_repository_impl.dart';

final rewriteHistoryProvider = savedListProvider(
  currentUserIdProvider,
  (ref, userId) => ref.watch(rewriteRepositoryProvider).history(userId),
);
