// FILE: features/conversation/domain/entities/reply_event.dart
// What arrives while Claude writes a reply: reasoning, pieces of text, searches and sources, then
// how it ended.

import 'source.dart';

sealed class ReplyEvent {
  const ReplyEvent();
}

/// The next piece of Claude's summarized reasoning.
class ReplyThinking extends ReplyEvent {
  const ReplyThinking(this.text);
  final String text;
}

/// The next piece of the reply, to append to what is already on screen.
class ReplyText extends ReplyEvent {
  const ReplyText(this.text);
  final String text;
}

/// Claude searched the web for [query].
class ReplySearch extends ReplyEvent {
  const ReplySearch(this.query);
  final String query;
}

/// Claude cited [source] in the text it is writing.
class ReplySource extends ReplyEvent {
  const ReplySource(this.source);
  final Source source;
}

/// The reply finished. [stopReason] is "end_turn" normally, or "refusal" / "max_tokens".
/// [content] is Claude's whole turn, kept so the conversation can continue.
class ReplyDone extends ReplyEvent {
  const ReplyDone(this.stopReason, {this.content = const []});
  final String? stopReason;
  final List<Map<String, dynamic>> content;
}

/// The server could not finish the reply. [message] is safe to show.
class ReplyFailed extends ReplyEvent {
  const ReplyFailed(this.message);
  final String message;
}
