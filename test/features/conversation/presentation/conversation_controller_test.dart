import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/features/conversation/data/repositories/conversation_repository_impl.dart';
import 'package:parley/features/conversation/domain/entities/chat_message.dart';
import 'package:parley/features/conversation/domain/entities/conversation_kind.dart';
import 'package:parley/features/conversation/domain/entities/reply_event.dart';
import 'package:parley/features/conversation/domain/repositories/conversation_repository.dart';
import 'package:parley/features/conversation/presentation/providers/conversation_controller.dart';

/// Hands each reply() call a stream the test drives by hand.
class _ManualReplies implements ConversationRepository {
  final streams = <StreamController<ReplyEvent>>[];
  final histories = <List<ChatMessage>>[];

  @override
  Stream<ReplyEvent> reply({
    required ConversationKind kind,
    required ClaudeModel model,
    required List<ChatMessage> history,
    CancelToken? cancel,
  }) {
    histories.add(history);
    final controller = StreamController<ReplyEvent>();
    cancel?.whenCancelled.then((_) => controller.close());
    streams.add(controller);
    return controller.stream;
  }
}

void main() {
  late _ManualReplies replies;
  late ProviderContainer container;

  setUp(() {
    replies = _ManualReplies();
    container = ProviderContainer(
      overrides: [conversationRepositoryProvider.overrideWithValue(replies)],
    );
    addTearDown(container.dispose);
  });

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
}
