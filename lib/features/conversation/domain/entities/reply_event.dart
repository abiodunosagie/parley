// FILE: features/conversation/domain/entities/reply_event.dart
// What arrives while Claude writes a reply: pieces of text, then how it ended.

sealed class ReplyEvent {
  const ReplyEvent();
}

/// The next piece of the reply, to append to what is already on screen.
class ReplyText extends ReplyEvent {
  const ReplyText(this.text);
  final String text;
}

/// The reply finished. [stopReason] is "end_turn" normally, or "refusal" / "max_tokens".
class ReplyDone extends ReplyEvent {
  const ReplyDone(this.stopReason);
  final String? stopReason;
}

/// The server could not finish the reply. [message] is safe to show.
class ReplyFailed extends ReplyEvent {
  const ReplyFailed(this.message);
  final String message;
}
