// FILE: features/conversation/presentation/screens/chat_screen.dart
// FEATURE 1 SCREEN: streaming chat. Example prompts while empty, the conversation otherwise.
// All logic is in ConversationController (chatControllerProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/screen_intro.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../providers/conversation_controller.dart';
import '../widgets/conversation_view.dart';
import '../../../../core/widgets/intro_list.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  static const _starters = [
    'Explain how streaming works in a chat app, simply',
    'Write a Flutter widget that shows a countdown timer',
    'Give me three interview questions about React Native and answer them',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Chat',
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: state.isEmpty ? null : controller.reset,
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: ConversationView(
        state: state,
        onSend: controller.send,
        onStop: controller.stop,
        empty: IntroList(
          header: const ScreenIntro(
            title: 'Ask anything.',
            body: 'Replies stream in as Claude writes them. Switch models from the top right.',
          ),
          starters: _starters,
          onPick: controller.send,
        ),
      ),
    );
  }
}
