// FILE: features/conversation/domain/entities/chat_message.dart
// One turn in a Chat, Look or Read conversation: who said it, the text, an optional photo or PDF,
// and for Claude's replies the reasoning, the web searches, the cited sources, and the turn
// exactly as the API returned it (sent back unchanged on the next request).
// How it is sent to the server lives in data/mappers/chat_message_mapper.dart.

import 'package:meta/meta.dart';

import 'attachment.dart';
import 'source.dart';

@immutable
class ChatMessage {
  const ChatMessage({
    required this.fromUser,
    required this.text,
    this.attachment,
    this.thinking = '',
    this.searches = const [],
    this.sources = const [],
    this.replay = const [],
  });

  final bool fromUser;
  final String text;
  final Attachment? attachment;

  /// Claude's summarized reasoning for this reply. Empty when it answered without thinking.
  final String thinking;

  /// What Claude searched the web for while writing this reply.
  final List<String> searches;
  final List<Source> sources;

  /// Claude's turn as the API returned it: thinking with its signature, searches with their
  /// encrypted results, cited text. Empty for your messages and for replies that were stopped.
  final List<Map<String, dynamic>> replay;

  ChatMessage copyWith({
    String? text,
    String? thinking,
    List<String>? searches,
    List<Source>? sources,
    List<Map<String, dynamic>>? replay,
  }) => ChatMessage(
    fromUser: fromUser,
    text: text ?? this.text,
    attachment: attachment,
    thinking: thinking ?? this.thinking,
    searches: searches ?? this.searches,
    sources: sources ?? this.sources,
    replay: replay ?? this.replay,
  );
}
