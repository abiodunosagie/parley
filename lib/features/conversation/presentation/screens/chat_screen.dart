// FILE: features/conversation/presentation/screens/chat_screen.dart
// FEATURE 1 SCREEN: streaming chat, with Claude's reasoning on show and optional web search with
// cited sources. While empty it greets you by name and offers example prompts; otherwise it shows
// the conversation. History in the app bar.
// All logic is in ConversationController (chatControllerProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/intro_list.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../../domain/entities/conversation_kind.dart';
import '../providers/conversation_controller.dart';
import '../widgets/conversation_view.dart';
import '../widgets/greeting.dart';
import '../widgets/history_button.dart';
import '../widgets/web_search_toggle.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  static const _starters = [
    'Explain how streaming works in a chat app, simply',
    'What changed in the latest Flutter release?',
    'Plan a three-day trip to Lisbon on a budget',
    'Give me three interview questions about React Native and answer them',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final firstName = ref.watch(
      currentUserProvider.select((user) => user.value?.firstName ?? ''),
    );

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Chat',
        actions: [
          ConversationHistoryButton(
            kind: ConversationKind.chat,
            controller: controller,
          ),
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
        aboveComposer: WebSearchToggle(
          on: state.webSearch,
          enabled: !state.busy,
          onChanged: controller.setWebSearch,
        ),
        empty: IntroList(
          header: ScreenIntro(
            title: greetingFor(DateTime.now(), firstName),
            body: 'Replies stream in as Claude writes them, with its reasoning one tap away. Turn on web search for anything current.',
          ),
          starters: _starters,
          onPick: controller.send,
        ),
      ),
    );
  }
}
