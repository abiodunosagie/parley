// FILE: features/tasks/presentation/providers/agent_history_provider.dart
// The saved Tasks conversations for the signed-in account, newest first.

import '../../../../core/state/saved_history.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/agent_history_repository_impl.dart';

final agentHistoryProvider = savedListProvider(
  currentUserIdProvider,
  (ref, userId) => ref.watch(agentHistoryRepositoryProvider).history(userId),
);
