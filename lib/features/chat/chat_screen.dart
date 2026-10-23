// FILE: features/chat/chat_screen.dart
// FEATURE 1 SCREEN: streaming chat. Shows example prompts when empty, the conversation
// otherwise, and the composer at the bottom. All logic is in conversation.dart (chatProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/account_button.dart';
import '../../shared/blocks.dart';
import '../../shared/composer.dart';
import '../../shared/model_picker.dart';
import '../conversation/conversation.dart';
import '../conversation/message_list.dart';

/// Feature 1: streaming chat. Text appears token by token as Claude writes it.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  static const _starters = [
    'Explain how streaming works in a chat app, simply',
    'Write a Flutter widget that shows a countdown timer',
    'Give me three interview questions about React Native and answer them',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatProvider);
    final chat = ref.read(chatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          const ModelPickerButton(),
          IconButton(
            tooltip: 'New chat',
            onPressed: state.messages.isEmpty ? null : chat.reset,
            icon: const Icon(Icons.edit_square),
          ),
          const AccountButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const ScreenIntro(
                        title: 'Ask anything.',
                        body: 'Replies stream in as Claude writes them. Switch models from the top right.',
                      ),
                      StarterButtons(items: _starters, onPick: chat.send),
                    ],
                  )
                : MessageList(messages: state.messages, busy: state.busy),
          ),
          if (state.notice != null) Notice(state.notice!),
          Composer(busy: state.busy, onSend: chat.send, onStop: chat.stop),
        ],
      ),
    );
  }
}
