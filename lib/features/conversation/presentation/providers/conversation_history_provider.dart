// FILE: features/conversation/presentation/providers/conversation_history_provider.dart
// The saved conversations of one feature (Chat, Look or Read) for the signed-in account, newest
// first. One list per kind.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../../core/state/saved_history.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/conversation_history_repository_impl.dart';
import '../../domain/entities/conversation_kind.dart';

final _lists = {
  for (final kind in ConversationKind.values)
    kind: savedListProvider(
      currentUserIdProvider,
      (ref, userId) => ref
          .watch(conversationHistoryRepositoryProvider)
          .history(userId, kind),
    ),
};

/// The history list for [kind].
FutureProvider<List<SavedSummary>> conversationHistoryProvider(
  ConversationKind kind,
) => _lists[kind]!;
