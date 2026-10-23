// FILE: features/receipt/presentation/providers/receipt_history_provider.dart
// The receipts the signed-in account scanned, newest first.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/receipt_repository_impl.dart';

final receiptHistoryProvider = FutureProvider.autoDispose<List<SavedSummary>>((
  ref,
) async {
  final userId = ref.watch(
    currentUserProvider.select((user) => user.value?.id),
  );
  if (userId == null) return const [];
  return ref.watch(receiptRepositoryProvider).history(userId);
});
