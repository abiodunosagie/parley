// FILE: features/conversation/presentation/providers/conversation_controller.dart
// FEATURE 1, 2 AND 3 LOGIC: a streamed conversation with Claude, used by Chat, Look and Read.
// Chat uses this controller as is; Look and Read extend it with the photo or PDF
// (look_controller.dart, read_controller.dart).
// The flow of `send()`:
//   1. Add your message and an empty reply bubble to the screen.
//   2. Ask ConversationRepository.reply() for the reply.
//   3. Reasoning, text, searches and sources land in the reply bubble as they arrive.
//   4. When the stream ends, keep Claude's turn for the next request, save the conversation, and
//      show a note if Claude stopped early or something failed.
// `_current` makes sure an old reply that is still arriving can never write into a new chat.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/error_log.dart';
import '../../../../core/errors/user_messages.dart';
import '../../../../core/network/cancel_token.dart';
import '../../../../core/state/saved_history.dart';
import '../../../../core/state/selected_model_provider.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/conversation_history_repository_impl.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/entities/reply_event.dart';
import '../../domain/entities/source.dart';
import 'conversation_history_provider.dart';
import 'conversation_state.dart';

class ConversationController extends Notifier<ConversationState>
    with SavedHistory<ConversationState> {
  ConversationController(this.kind);
  final ConversationKind kind;

  static const _uuid = Uuid();

  /// The send that owns the state. Starting over replaces it, and an older send that is still
  /// unwinding sees it is no longer current and stops touching the state.
  CancelToken? _current;

  @override
  ConversationState build() {
    // Signing out disposes this controller: stop the running request so it stops spending.
    ref.onDispose(() => _current?.cancel());
    return const ConversationState();
  }

  @override
  String? get historyUserId => ref.read(currentUserIdProvider);

  @override
  ProviderOrFamily get historyList => conversationHistoryProvider(kind);

  void reset() {
    abandonCurrent();
    state = ConversationState(webSearch: state.webSearch);
  }

  void stop() => _current?.cancel();

  /// Chat only: lets Claude search the web from the next message on.
  void setWebSearch(bool on) => state = state.copyWith(webSearch: on);

  /// Cancels any running reply and stops it from touching the state again.
  @protected
  void abandonCurrent() {
    _current?.cancel();
    _current = null;
  }

  /// Opens a saved conversation from history, ready to carry on.
  Future<void> open(String id) async {
    final saved = await loadSaved(
      (userId) => ref
          .read(conversationHistoryRepositoryProvider)
          .load(userId, kind, id),
    );
    if (!ref.mounted) return;
    if (saved == null) {
      // Keep what is on screen; only say the saved one could not be read.
      state = state.copyWith(
        notice: () => 'That conversation could not be opened.',
      );
      return;
    }
    abandonCurrent();
    state = ConversationState(
      id: saved.id,
      messages: saved.messages,
      attachment: saved.attachment,
      model: saved.model,
      webSearch: saved.webSearch,
    );
  }

  /// Deletes a saved conversation. Deleting the one on screen also clears the screen.
  Future<void> deleteSaved(String id) async {
    final deleted = await changeSaved(
      (userId) => ref
          .read(conversationHistoryRepositoryProvider)
          .delete(userId, kind, id),
    );
    if (!ref.mounted) return;
    if (state.id == id) {
      reset();
    } else if (!deleted) {
      state = state.copyWith(
        notice: () => 'That conversation could not be deleted.',
      );
    }
  }

  Future<void> send(String text) async {
    if (state.busy) return;
    final selected = ref.read(selectedModelProvider);
    final model = state.model ?? selected;
    final user = ChatMessage(
      fromUser: true,
      text: text,
      attachment: state.isEmpty ? state.attachment : null,
    );
    final history = [...state.messages, user];
    state = state.copyWith(
      id: state.id ?? _uuid.v4(),
      model: model,
      messages: [
        ...history,
        const ChatMessage(fromUser: false, text: ''),
      ],
      status: ReplyStatus.streaming,
      notice: () => null,
    );

    final token = _current = CancelToken();
    bool stillMine() => ref.mounted && identical(_current, token);
    final reply = _ReplyBuilder();
    String? notice;
    var finished = false;
    try {
      final events = ref
          .read(conversationRepositoryProvider)
          .reply(
            kind: kind,
            model: model,
            history: history,
            webSearch: state.webSearch,
            cancel: token,
          );
      await for (final event in events) {
        if (!stillMine()) return;
        switch (event) {
          case ReplyDone(:final stopReason, :final content):
            finished = true;
            notice = stopReasonNote(stopReason);
            // A cut-short turn is not replayed: its text alone is the safer history.
            if (stopReason == 'end_turn') reply.replay = content;
          case ReplyFailed(:final message):
            finished = true;
            notice = message;
          default:
            reply.add(event);
        }
        _showReply(reply.build());
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
    if (notice == null && model != selected) {
      notice =
          'This conversation stays on ${model.label}. Start a new one to use another model.';
    }
    // A reply that never started is removed, so the next send does not carry an empty turn.
    state = state.copyWith(
      messages: reply.isEmpty ? history : state.messages,
      status: ReplyStatus.idle,
      notice: () => notice,
    );
    await _save();
  }

  void _showReply(ChatMessage reply) {
    final messages = [...state.messages];
    messages[messages.length - 1] = reply;
    state = state.copyWith(messages: messages);
  }

  Future<void> _save() async {
    final id = state.id;
    final model = state.model;
    if (id == null || model == null || state.isEmpty) return;
    final conversation = Conversation(
      id: id,
      kind: kind,
      model: model,
      messages: state.messages,
      updatedAt: DateTime.now(),
      attachment: state.attachment,
      webSearch: state.webSearch,
    );
    await changeSaved(
      (userId) => ref
          .read(conversationHistoryRepositoryProvider)
          .save(userId, conversation),
    );
  }
}

/// Collects one streamed reply: reasoning, text, searches and sources (each source once).
class _ReplyBuilder {
  final _thinking = StringBuffer();
  final _text = StringBuffer();
  final _searches = <String>[];
  final _sources = <String, Source>{};
  List<Map<String, dynamic>> replay = const [];

  /// No reply text yet. Reasoning alone is not a reply, so a reply stopped while Claude was
  /// still thinking is dropped.
  bool get isEmpty => _text.isEmpty;

  void add(ReplyEvent event) {
    switch (event) {
      case ReplyThinking(:final text):
        _thinking.write(text);
      case ReplyText(:final text):
        _text.write(text);
      case ReplySearch(:final query):
        _searches.add(query);
      case ReplySource(:final source):
        _sources.putIfAbsent(source.key, () => source);
      case ReplyDone() || ReplyFailed():
        break;
    }
  }

  ChatMessage build() => ChatMessage(
    fromUser: false,
    text: _text.toString(),
    thinking: _thinking.toString(),
    searches: List.unmodifiable(_searches),
    sources: List.unmodifiable(_sources.values),
    replay: replay,
  );
}

final chatControllerProvider =
    NotifierProvider<ConversationController, ConversationState>(
      () => ConversationController(ConversationKind.chat),
    );
