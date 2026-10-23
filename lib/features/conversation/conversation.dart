import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/claude_api.dart';
import '../../core/claude_models.dart';
import '../../core/sse.dart';
import 'attachment.dart';

@immutable
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text, this.attachment});
  final bool fromUser;
  final String text;
  final Attachment? attachment;

  ChatMessage withText(String value) => ChatMessage(fromUser: fromUser, text: value, attachment: attachment);

  /// The Messages API shape: plain text, or an image block followed by the question.
  Map<String, dynamic> toApi() {
    final role = fromUser ? 'user' : 'assistant';
    final image = attachment;
    if (image == null) return {'role': role, 'content': text};
    return {
      'role': role,
      'content': [
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': image.mediaType, 'data': base64Encode(image.bytes)},
        },
        {'type': 'text', 'text': text},
      ],
    };
  }
}

@immutable
class ConversationState {
  const ConversationState({this.messages = const [], this.busy = false, this.notice, this.photo});
  final List<ChatMessage> messages;
  final bool busy;
  final String? notice;

  /// The photo a vision conversation is about. It rides on the first user message.
  final Attachment? photo;
}

/// Runs one streamed conversation with Claude. Chat and vision each get their own instance.
class ConversationController extends Notifier<ConversationState> {
  ConversationController(this.mode);
  final ClaudeMode mode;

  /// The send that owns the state. Starting over replaces it, and an older send that is still
  /// unwinding sees it is no longer current and stops touching the state.
  CancelToken? _current;

  @override
  ConversationState build() => const ConversationState();

  /// A new photo starts a new conversation about it.
  void attachPhoto(Attachment photo) {
    _abandon();
    state = ConversationState(photo: photo);
  }

  void reset() {
    _abandon();
    state = const ConversationState();
  }

  void stop() => _current?.cancel();

  void _abandon() {
    _current?.cancel();
    _current = null;
  }

  Future<void> send(String text) async {
    if (state.busy) return;
    final firstTurn = state.messages.isEmpty;
    final user = ChatMessage(fromUser: true, text: text, attachment: firstTurn ? state.photo : null);
    final history = [...state.messages, user];
    state = ConversationState(
      messages: [...history, const ChatMessage(fromUser: false, text: '')],
      busy: true,
      photo: state.photo,
    );

    final token = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, token);
    final reply = StringBuffer();
    String? notice;
    var done = false;
    try {
      final events = ref.read(claudeApiProvider).stream(
            mode: mode,
            model: ref.read(selectedModelProvider),
            messages: [for (final m in history) m.toApi()],
            cancel: token,
          );
      await for (final event in events) {
        if (!stillMine()) return;
        switch (event) {
          case TextDelta(:final text):
            reply.write(text);
            _showReply(reply.toString());
          case StreamDone(:final stopReason):
            done = true;
            notice = stopReasonNote(stopReason);
          case StreamFailed(:final message):
            done = true;
            notice = message;
        }
      }
      if (!done) {
        notice = token.isCancelled ? 'Stopped.' : 'The connection dropped before the reply finished.';
      }
    } catch (e) {
      notice = noticeFor(e, cancelled: token.isCancelled, tag: 'stream');
    }

    if (!stillMine()) return;
    _current = null;
    // A reply that never started is removed, so the next send does not carry an empty turn.
    state = ConversationState(
      messages: reply.isEmpty ? history : state.messages,
      notice: notice,
      photo: state.photo,
    );
  }

  void _showReply(String text) {
    final messages = [...state.messages];
    messages[messages.length - 1] = messages.last.withText(text);
    state = ConversationState(messages: messages, busy: true, photo: state.photo);
  }
}

final chatProvider =
    NotifierProvider<ConversationController, ConversationState>(() => ConversationController(ClaudeMode.chat));

final visionProvider =
    NotifierProvider<ConversationController, ConversationState>(() => ConversationController(ClaudeMode.vision));
