// FILE: features/conversation/presentation/providers/conversation_controller.dart
// FEATURE 1 AND 2 LOGIC: a streamed conversation with Claude, used by Chat and Look.
// Chat uses this controller as is; Look extends it with the photo (LookController below).
// The flow of `send()`:
//   1. Add your message and an empty reply bubble to the screen.
//   2. Ask ConversationRepository.reply() for the reply.
//   3. Each ReplyText appends to the reply bubble, so the text appears as Claude writes it.
//   4. When the stream ends, show a note if Claude stopped early or something failed.
// `_current` makes sure an old reply that is still arriving can never write into a new chat.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_log.dart';
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

  void reset() {
    _abandon();
    state = const ConversationState();
  }

  void stop() => _current?.cancel();

  /// Cancels any running reply and stops it from touching the state again.
  @protected
  void abandonCurrent() => _abandon();

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
    state = state.copyWith(
      messages: [
        ...history,
        const ChatMessage(fromUser: false, text: ''),
      ],
      status: ReplyStatus.streaming,
      notice: () => null,
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
      notice = reportError(e, cancelled: token.isCancelled, tag: 'stream');
    }

    if (!stillMine()) return;
    _current = null;
    // A reply that never started is removed, so the next send does not carry an empty turn.
    state = state.copyWith(
      messages: reply.isEmpty ? history : state.messages,
      status: ReplyStatus.idle,
      notice: () => notice,
    );
  }

  void _showReply(String text) {
    final messages = [...state.messages];
    messages[messages.length - 1] = messages.last.withText(text);
    state = state.copyWith(messages: messages);
  }
}

final chatControllerProvider =
    NotifierProvider<ConversationController, ConversationState>(
      () => ConversationController(ConversationKind.chat),
    );

/// Look: the same streamed conversation, plus the photo it is about.
class LookController extends ConversationController {
  LookController() : super(ConversationKind.vision);

  /// Takes or picks a photo and starts a new conversation about it. When the photo cannot be
  /// used (access denied, unsupported file) the reason lands in `notice`.
  Future<void> pickPhoto(PhotoSource source) async {
    try {
      final photo = await ref.read(photoRepositoryProvider).pick(source);
      if (photo == null || !ref.mounted) return;
      abandonCurrent();
      state = ConversationState(photo: photo);
    } on AppException catch (e) {
      if (ref.mounted) state = state.copyWith(notice: () => e.message);
    }
  }
}

final lookControllerProvider =
    NotifierProvider<LookController, ConversationState>(LookController.new);
