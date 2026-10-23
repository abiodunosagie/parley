// FILE: features/conversation/data/repositories/conversation_repository_impl.dart
// The real ConversationRepository: sends the history to the `claude` function through
// ClaudeClient and turns the server's stream events into domain ReplyEvents.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/claude_model.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/network/claude_client.dart';
import '../../../../core/network/sse.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/entities/reply_event.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../mappers/chat_message_mapper.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._client);
  final ClaudeClient _client;

  @override
  Stream<ReplyEvent> reply({
    required ConversationKind kind,
    required ClaudeModel model,
    required List<ChatMessage> history,
    CancelToken? cancel,
  }) => _client
      .stream(
        mode: kind == ConversationKind.chat
            ? ClaudeMode.chat
            : ClaudeMode.vision,
        model: model,
        messages: [for (final m in history) m.toApi()],
        cancel: cancel,
      )
      .map(
        (event) => switch (event) {
          TextDelta(:final text) => ReplyText(text),
          StreamDone(:final stopReason) => ReplyDone(stopReason),
          StreamFailed(:final message) => ReplyFailed(message),
        },
      );
}

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepositoryImpl(ref.watch(claudeClientProvider)),
);
