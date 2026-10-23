// FILE: features/conversation/presentation/providers/conversation_history_provider.dart
// The saved conversations of one feature (Chat, Look or Read) for the signed-in account, newest
// first. Reloads when the account changes or a conversation is saved or deleted.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/saved_summary.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/conversation_history_repository_impl.dart';
import '../../domain/entities/conversation_kind.dart';

final conversationHistoryProvider = FutureProvider.autoDispose
    .family<List<SavedSummary>, ConversationKind>((ref, kind) async {
      final userId = ref.watch(
        currentUserProvider.select((user) => user.value?.id),
      );
      if (userId == null) return const [];
      return ref
          .watch(conversationHistoryRepositoryProvider)
          .list(userId, kind);
    });
