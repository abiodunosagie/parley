// FILE: features/tasks/presentation/providers/agent_history_provider.dart
// The saved Tasks conversations for the signed-in account, newest first. Reloads when the account
// changes or a conversation is saved or deleted.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/agent_history_repository_impl.dart';

final agentHistoryProvider = FutureProvider.autoDispose<List<SavedSummary>>((
  ref,
) async {
  final userId = ref.watch(
    currentUserProvider.select((user) => user.value?.id),
  );
  if (userId == null) return const [];
  return ref.watch(agentHistoryRepositoryProvider).list(userId);
});
