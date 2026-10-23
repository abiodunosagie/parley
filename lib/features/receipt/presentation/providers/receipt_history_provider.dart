// FILE: features/receipt/presentation/providers/receipt_history_provider.dart
// The receipts the signed-in account scanned, newest first.

import '../../../../core/state/saved_history.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/receipt_repository_impl.dart';

final receiptHistoryProvider = savedListProvider(
  currentUserIdProvider,
  (ref, userId) => ref.watch(receiptRepositoryProvider).history(userId),
);
