// FILE: features/rewrite/presentation/providers/rewrite_history_provider.dart
// The signed-in account's saved rewrites, newest first.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/rewrite_repository_impl.dart';

final rewriteHistoryProvider = FutureProvider.autoDispose<List<SavedSummary>>((
  ref,
) async {
  final userId = ref.watch(
    currentUserProvider.select((user) => user.value?.id),
  );
  if (userId == null) return const [];
  return ref.watch(rewriteRepositoryProvider).history(userId);
});
