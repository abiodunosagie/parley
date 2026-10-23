// FILE: features/extract/presentation/providers/extract_history_provider.dart
// The job posts the signed-in account extracted, newest first.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/extract_repository_impl.dart';

final extractHistoryProvider = FutureProvider.autoDispose<List<SavedSummary>>((
  ref,
) async {
  final userId = ref.watch(
    currentUserProvider.select((user) => user.value?.id),
  );
  if (userId == null) return const [];
  return ref.watch(extractRepositoryProvider).history(userId);
});
