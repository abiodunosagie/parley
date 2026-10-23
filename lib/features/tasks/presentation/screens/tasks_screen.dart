// FILE: features/tasks/presentation/screens/tasks_screen.dart
// FEATURE 4 SCREEN: your task list on top, the conversation below. Each lightning line is a tool
// Claude chose to call. Logic: agentControllerProvider and taskListControllerProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/composer.dart';
import '../../../../core/widgets/intro_list.dart';
import '../../../../core/widgets/model_picker_button.dart';
import '../../../../core/widgets/notice_line.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../auth/presentation/widgets/account_button.dart';
import '../providers/agent_controller.dart';
import '../widgets/agent_item_view.dart';
import '../widgets/task_panel.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  static const _starters = [
    'Add "buy milk" for tomorrow, high priority',
    'What is on my list?',
    'Remind me in 2 minutes to stretch',
    'Mark the milk task as done',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentControllerProvider);
    final agent = ref.read(agentControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const ModelPickerButton(),
          IconButton(
            tooltip: 'New conversation',
            onPressed: state.isEmpty ? null : agent.reset,
            icon: const Icon(Icons.edit_square),
          ),
          const AccountButton(),
        ],
      ),
      body: Column(
        children: [
          const TaskPanel(),
          Expanded(
            child: state.isEmpty
                ? IntroList(
                    header: const ScreenIntro(
                      title: 'Claude runs the app.',
                      body: 'Each lightning line is a tool Claude chose to call. The app runs it on your phone and reports back.',
                    ),
                    starters: _starters,
                    onPick: agent.send,
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.items.length,
                    itemBuilder: (context, i) => AgentItemView(state.items[i]),
                  ),
          ),
          if (state.running) const LinearProgressIndicator(minHeight: 2),
          if (state.notice != null) Notice(state.notice!),
          Composer(
            busy: state.running,
            onSend: agent.send,
            onStop: agent.stop,
            hint: 'Ask Parley to manage tasks',
          ),
        ],
      ),
    );
  }
}
