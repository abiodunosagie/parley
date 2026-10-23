// FILE: features/conversation/domain/repositories/conversation_repository.dart
// Asks Claude for the next reply in a conversation, streamed piece by piece.
// Implemented in data/repositories/conversation_repository_impl.dart.

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../entities/chat_message.dart';
import '../entities/conversation_kind.dart';
import '../entities/reply_event.dart';

abstract interface class ConversationRepository {
  /// Streams Claude's reply to [history] (which ends with the user's latest message).
  /// Cancelling [cancel] ends the stream quietly. Throws AppException when the request fails.
  Stream<ReplyEvent> reply({
    required ConversationKind kind,
    required ClaudeModel model,
    required List<ChatMessage> history,
    CancelToken? cancel,
  });
}
