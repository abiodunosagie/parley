// FILE: core/sse.dart
// Reads the live stream the server sends while Claude is writing a reply.
// The server sends lines like `data: {"type":"text","text":"Hel"}`. This file turns those lines into
// Dart objects (TextDelta, StreamDone, StreamFailed) that the chat screen can switch on.

import 'dart:convert';

/// One event from the `claude` function's stream.
sealed class StreamEvent {
  const StreamEvent();

  /// Null for event types this app version does not know, so a newer server never breaks it.
  static StreamEvent? fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'text' => TextDelta(json['text'] as String),
        'done' => StreamDone(json['stop_reason'] as String?),
        'error' => StreamFailed(
          json['message'] as String? ?? 'Something went wrong. Try again.',
        ),
        _ => null,
      };
}

class TextDelta extends StreamEvent {
  const TextDelta(this.text);
  final String text;
}

class StreamDone extends StreamEvent {
  const StreamDone(this.stopReason);
  final String? stopReason;
}

class StreamFailed extends StreamEvent {
  const StreamFailed(this.message);
  final String message;
}

/// Turns server-sent-event bytes into [StreamEvent]s. The server writes one JSON object per
/// `data:` line, followed by a blank line; anything else on the wire is skipped.
///
/// `bind` rather than `transform`, so a `Stream<Uint8List>` works too: the decoder is typed
/// for `List<int>` and `transform` would fail on the narrower stream type at runtime.
Stream<StreamEvent> parseSse(Stream<List<int>> bytes) => utf8.decoder
    .bind(bytes)
    .transform(const LineSplitter())
    .where((line) => line.startsWith('data: '))
    .map(
      (line) => StreamEvent.fromJson(
        jsonDecode(line.substring(6)) as Map<String, dynamic>,
      ),
    )
    .where((event) => event != null)
    .cast<StreamEvent>();
