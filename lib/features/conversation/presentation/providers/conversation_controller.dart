// FILE: features/conversation/presentation/providers/conversation_controller.dart
// FEATURE 1 AND 2 LOGIC: a streamed conversation with Claude, used by Chat and Look.
// The flow of `send()`:
//   1. Add your message and an empty reply bubble to the screen.
//   2. Ask ConversationRepository.reply() for the reply.
//   3. Each ReplyText appends to the reply bubble, so the text appears as Claude writes it.
//   4. When the stream ends, show a note if Claude stopped early or something failed.
// `_current` makes sure an old reply that is still arriving can never write into a new chat.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/entities/reply_event.dart';
import '../../domain/repositories/photo_repository.dart';
import 'conversation_state.dart';

class ConversationController extends Notifier<ConversationState> {
  ConversationController(this.kind);
  final ConversationKind kind;

  /// The send that owns the state. Starting over replaces it, and an older send that is still
  /// unwinding sees it is no longer current and stops touching the state.
  CancelToken? _current;

  @override
  ConversationState build() {
    // Signing out disposes this controller: stop the running request so it stops spending.
    ref.onDispose(() => _current?.cancel());
    return const ConversationState();
  }

  /// Look: takes or picks a photo and starts a new conversation about it. Returns a message to
  /// show when it could not get one (access denied, unsupported file), or null.
  Future<String?> pickPhoto(PhotoSource source) async {
    try {
      final photo = await ref.read(photoRepositoryProvider).pick(source);
      if (photo == null || !ref.mounted) return null;
      _abandon();
      state = ConversationState(photo: photo);
      return null;
    } on AppException catch (e) {
      return e.message;
    }
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
    final user = ChatMessage(
      fromUser: true,
      text: text,
      attachment: state.isEmpty ? state.photo : null,
    );
    final history = [...state.messages, user];
    state = ConversationState(
      messages: [
        ...history,
        const ChatMessage(fromUser: false, text: ''),
      ],
      status: ReplyStatus.streaming,
      photo: state.photo,
    );

    final token = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, token);
    final reply = StringBuffer();
    String? notice;
    var finished = false;
    try {
      final events = ref
          .read(conversationRepositoryProvider)
          .reply(
            kind: kind,
            model: ref.read(selectedModelProvider),
            history: history,
            cancel: token,
          );
      await for (final event in events) {
        if (!stillMine()) return;
        switch (event) {
          case ReplyText(:final text):
            reply.write(text);
            _showReply(reply.toString());
          case ReplyDone(:final stopReason):
            finished = true;
            notice = stopReasonNote(stopReason);
          case ReplyFailed(:final message):
            finished = true;
            notice = message;
        }
      }
      if (!finished) {
        notice = token.isCancelled
            ? 'Stopped.'
            : 'The connection dropped before the reply finished.';
      }
    } catch (e) {
      notice = messageFor(e, cancelled: token.isCancelled, tag: 'stream');
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
    state = ConversationState(
      messages: messages,
      status: ReplyStatus.streaming,
      photo: state.photo,
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ConversationController, ConversationState>(
      () => ConversationController(ConversationKind.chat),
    );

final lookControllerProvider =
    NotifierProvider<ConversationController, ConversationState>(
      () => ConversationController(ConversationKind.vision),
    );
