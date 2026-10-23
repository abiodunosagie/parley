import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/core/state/selected_model_provider.dart';
import 'package:parley/core/storage/local_store.dart';
import 'package:parley/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parley/features/auth/domain/entities/app_user.dart';
import 'package:parley/features/conversation/data/repositories/conversation_repository_impl.dart';
import 'package:parley/features/conversation/domain/entities/chat_message.dart';
import 'package:parley/features/conversation/domain/entities/conversation_kind.dart';
import 'package:parley/features/conversation/domain/entities/reply_event.dart';
import 'package:parley/features/conversation/domain/entities/source.dart';
import 'package:parley/features/conversation/domain/repositories/conversation_repository.dart';
import 'package:parley/features/conversation/presentation/providers/conversation_controller.dart';
import 'package:parley/features/conversation/presentation/providers/conversation_history_provider.dart';

import '../../../helpers/fakes.dart';

/// Hands each reply() call a stream the test drives by hand.
class _ManualReplies implements ConversationRepository {
  final streams = <StreamController<ReplyEvent>>[];
  final histories = <List<ChatMessage>>[];
  final searches = <bool>[];

  @override
  Stream<ReplyEvent> reply({
    required ConversationKind kind,
    required ClaudeModel model,
    required List<ChatMessage> history,
    bool webSearch = false,
    CancelToken? cancel,
  }) {
    histories.add(history);
    searches.add(webSearch);
    final controller = StreamController<ReplyEvent>();
    cancel?.whenCancelled.then((_) => controller.close());
    streams.add(controller);
    return controller.stream;
  }
}

void main() {
  late _ManualReplies replies;
  late MemoryStore store;
  late ProviderContainer container;

  setUp(() async {
    replies = _ManualReplies();
    store = MemoryStore();
    container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWithValue(replies),
        localStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(
          FakeAuth(const AppUser(id: 'u1', email: 'me@example.com')),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The signed-in user arrives through a stream; wait for it like the app does.
    container.listen(
      conversationHistoryProvider(ConversationKind.chat),
      (_, _) {},
    );
    await pumpEventQueue();
  });

  Future<void> finishReply(
    List<ReplyEvent> events,
    Future<void> sending,
  ) async {
    await pumpEventQueue();
    final stream = replies.streams.last;
    events.forEach(stream.add);
    await stream.close();
    await sending;
  }

  ConversationController chat() =>
      container.read(chatControllerProvider.notifier);

  test('streams the reply into the last message, then goes idle', () async {
    final sending = chat().send('Hi');
    await pumpEventQueue();
    expect(container.read(chatControllerProvider).busy, isTrue);

    replies.streams.single
      ..add(const ReplyText('Hel'))
      ..add(const ReplyText('lo'))
      ..add(const ReplyDone('end_turn'));
    await replies.streams.single.close();
    await sending;

    final state = container.read(chatControllerProvider);
    expect(state.busy, isFalse);
    expect(state.notice, isNull);
    expect([for (final m in state.messages) m.text], ['Hi', 'Hello']);
  });

  test('a refusal shows a note and keeps the text that arrived', () async {
    final sending = chat().send('Hi');
    await pumpEventQueue();
    replies.streams.single
      ..add(const ReplyText('Sorry'))
      ..add(const ReplyDone('refusal'));
    await replies.streams.single.close();
    await sending;
    expect(container.read(chatControllerProvider).notice, contains('declined'));
  });

  test(
    'Stop before any text removes the empty reply and says Stopped',
    () async {
      final sending = chat().send('Hi');
      await pumpEventQueue();
      chat().stop();
      await sending;
      final state = container.read(chatControllerProvider);
      expect(state.notice, 'Stopped.');
      expect(state.messages.single.text, 'Hi');
    },
  );

  test(
    'a reply still arriving after New chat never writes into the new chat',
    () async {
      unawaited(chat().send('First'));
      await pumpEventQueue();
      final old = replies.streams.single;
      chat().reset();
      old.add(const ReplyText('late text'));
      await pumpEventQueue();
      expect(container.read(chatControllerProvider).messages, isEmpty);
    },
  );

  test('a dropped connection without a done event says so', () async {
    final sending = chat().send('Hi');
    await pumpEventQueue();
    replies.streams.single.add(const ReplyText('Half'));
    await replies.streams.single.close();
    await sending;
    expect(
      container.read(chatControllerProvider).notice,
      'The connection dropped before the reply finished.',
    );
  });

  test(
    'reasoning, searches and sources land on the reply, each source once',
    () async {
      chat().setWebSearch(true);
      const source = Source.web(
        title: 'Docs',
        url: 'https://a.example',
        citedText: 'x',
      );
      await finishReply(const [
        ReplyThinking('Look it '),
        ReplyThinking('up.'),
        ReplySearch('flutter release'),
        ReplyText('3.47'),
        ReplySource(source),
        ReplySource(source),
        ReplyDone(
          'end_turn',
          content: [
            {'type': 'text', 'text': '3.47'},
          ],
        ),
      ], chat().send('Latest Flutter?'));

      final reply = container.read(chatControllerProvider).messages.last;
      expect(replies.searches.single, isTrue);
      expect(reply.thinking, 'Look it up.');
      expect(reply.searches, ['flutter release']);
      expect(reply.sources, hasLength(1));
      expect(reply.replay.single['text'], '3.47');
    },
  );

  test('a reply cut short is not kept for replay', () async {
    await finishReply(const [
      ReplyText('Long'),
      ReplyDone(
        'max_tokens',
        content: [
          {'type': 'text', 'text': 'Long'},
        ],
      ),
    ], chat().send('Hi'));
    expect(
      container.read(chatControllerProvider).messages.last.replay,
      isEmpty,
    );
  });

  test(
    'a finished conversation is saved and opens again from history',
    () async {
      await finishReply(const [
        ReplyText('Hello'),
        ReplyDone(
          'end_turn',
          content: [
            {'type': 'text', 'text': 'Hello'},
          ],
        ),
      ], chat().send('Hi there'));
      final id = container.read(chatControllerProvider).id!;

      final saved = await container.read(
        conversationHistoryProvider(ConversationKind.chat).future,
      );
      expect(saved.single.title, 'Hi there');

      chat().reset();
      await chat().open(id);
      final reopened = container.read(chatControllerProvider);
      expect(reopened.id, id);
      expect(
        [for (final m in reopened.messages) m.text],
        ['Hi there', 'Hello'],
      );
      expect(reopened.messages.last.replay, isNotEmpty);
    },
  );

  test(
    'deleting the conversation on screen clears it and its history entry',
    () async {
      await finishReply(const [
        ReplyText('Hello'),
        ReplyDone('end_turn'),
      ], chat().send('Hi'));
      final id = container.read(chatControllerProvider).id!;
      await chat().deleteSaved(id);
      expect(container.read(chatControllerProvider).isEmpty, isTrue);
      expect(
        await container.read(
          conversationHistoryProvider(ConversationKind.chat).future,
        ),
        isEmpty,
      );
    },
  );

  test('a conversation stays on its first model and says so', () async {
    await finishReply(const [
      ReplyText('One'),
      ReplyDone('end_turn'),
    ], chat().send('Hi'));
    final first = container.read(chatControllerProvider).model;
    container.read(selectedModelProvider.notifier).select(ClaudeModel.haiku);
    final sending = chat().send('Again');
    await finishReply(const [ReplyText('Two'), ReplyDone('end_turn')], sending);
    final state = container.read(chatControllerProvider);
    expect(state.model, first);
    expect(state.notice, contains('stays on'));
  });
}
