// FILE: features/extract/presentation/providers/extract_history_provider.dart
// The job posts the signed-in account extracted, newest first.

import '../../../../core/state/saved_history.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/extract_repository_impl.dart';

final extractHistoryProvider = savedListProvider(
  currentUserIdProvider,
  (ref, userId) => ref.watch(extractRepositoryProvider).history(userId),
);
