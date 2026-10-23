// FILE: core/network/sse.dart
// Reads the live stream the server sends while Claude is writing a reply.
// The server sends lines like `data: {"type":"text","text":"Hel"}`. This file turns those lines into
// Dart objects (ThinkingDelta, TextDelta, SearchRan, SourceCited, StreamDone, StreamFailed) that the
// conversation repository maps to domain events.

import 'dart:convert';

/// One event from the `claude` function's stream.
sealed class StreamEvent {
  const StreamEvent();

  /// Null for event types this app version does not know, so a newer server never breaks it.
  static StreamEvent? fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'thinking' => ThinkingDelta(json['text'] as String),
        'text' => TextDelta(json['text'] as String),
        'search' => SearchRan(json['query'] as String),
        'source' => SourceCited(
          Map<String, dynamic>.from(json['source'] as Map),
        ),
        'done' => StreamDone(
          json['stop_reason'] as String?,
          content: [
            for (final block in json['content'] as List? ?? const [])
              if (block is Map) Map<String, dynamic>.from(block),
          ],
        ),
        'error' => StreamFailed(
          json['message'] as String? ?? 'Something went wrong. Try again.',
        ),
        _ => null,
      };
}

/// A piece of Claude's summarized reasoning.
class ThinkingDelta extends StreamEvent {
  const ThinkingDelta(this.text);
  final String text;
}

class TextDelta extends StreamEvent {
  const TextDelta(this.text);
  final String text;
}

/// Claude searched the web for [query].
class SearchRan extends StreamEvent {
  const SearchRan(this.query);
  final String query;
}

/// A source Claude cited, as the server shaped it (`kind` is "web" or "page").
class SourceCited extends StreamEvent {
  const SourceCited(this.source);
  final Map<String, dynamic> source;
}

/// The reply finished. [content] is Claude's whole turn, to send back on the next request.
class StreamDone extends StreamEvent {
  const StreamDone(this.stopReason, {this.content = const []});
  final String? stopReason;
  final List<Map<String, dynamic>> content;
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
