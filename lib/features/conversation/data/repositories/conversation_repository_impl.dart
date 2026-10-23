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
import '../../domain/entities/source.dart';
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
    bool webSearch = false,
    CancelToken? cancel,
  }) async* {
    final events = _client.stream(
      mode: switch (kind) {
        ConversationKind.chat => ClaudeMode.chat,
        ConversationKind.vision => ClaudeMode.vision,
        ConversationKind.document => ClaudeMode.document,
      },
      model: model,
      messages: [for (final m in history) m.toApi()],
      webSearch: webSearch && kind == ConversationKind.chat,
      cancel: cancel,
    );
    await for (final event in events) {
      final mapped = switch (event) {
        ThinkingDelta(:final text) => ReplyThinking(text),
        TextDelta(:final text) => ReplyText(text),
        SearchRan(:final query) => ReplySearch(query),
        SourceCited(:final source) => switch (Source.fromJson(source)) {
          final s? => ReplySource(s),
          null => null,
        },
        StreamDone(:final stopReason, :final content) => ReplyDone(
          stopReason,
          content: content,
        ),
        StreamFailed(:final message) => ReplyFailed(message),
      };
      if (mapped != null) yield mapped;
    }
  }
}

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepositoryImpl(ref.watch(claudeClientProvider)),
);
