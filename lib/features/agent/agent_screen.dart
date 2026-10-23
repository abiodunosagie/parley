import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/account_button.dart';
import '../../shared/blocks.dart';
import '../../shared/composer.dart';
import '../../shared/model_picker.dart';
import 'agent_controller.dart';
import 'task_store.dart';

/// Feature 4 screen: talk to Claude, watch it call tools, see the task list change.
class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  static const _starters = [
    'Add "buy milk" for tomorrow, high priority',
    'What is on my list?',
    'Remind me in 2 minutes to stretch',
    'Mark the milk task as done',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentProvider);
    final agent = ref.read(agentProvider.notifier);
    final tasks = ref.watch(taskStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const ModelPickerButton(),
          IconButton(
            tooltip: 'New conversation',
            onPressed: state.items.isEmpty ? null : agent.reset,
            icon: const Icon(Icons.edit_square),
          ),
          const AccountButton(),
        ],
      ),
      body: Column(
        children: [
          _TaskPanel(tasks: tasks),
          Expanded(
            child: state.items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const ScreenIntro(
                        title: 'Claude runs the app.',
                        body: 'Each lightning line is a tool Claude chose to call. The app runs it on your phone and reports back.',
                      ),
                      StarterButtons(items: _starters, onPick: agent.send),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [for (final item in state.items) _ItemView(item)],
                  ),
          ),
          if (state.busy) const LinearProgressIndicator(minHeight: 2),
          if (state.notice != null) Notice(state.notice!),
          Composer(busy: state.busy, onSend: agent.send, onStop: agent.stop, hint: 'Ask Parley to manage tasks'),
        ],
      ),
    );
  }
}

class _TaskPanel extends ConsumerWidget {
  const _TaskPanel({required this.tasks});
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final store = ref.read(taskStoreProvider.notifier);
    return Container(
      constraints: const BoxConstraints(maxHeight: 210),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.line))),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No tasks yet. Ask Parley to add one.', style: TextStyle(color: colors.muted)),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final t in tasks)
                  Dismissible(
                    key: ValueKey(t.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => store.remove(t.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: colors.danger,
                      child: Icon(Icons.delete_outline, color: colors.background),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      value: t.done,
                      onChanged: (v) => store.setDone(t.id, done: v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        t.title,
                        style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null, color: colors.ink),
                      ),
                      subtitle: Text(
                        [if (t.dueDate.isNotEmpty) t.dueDate, '${t.priority} priority', 'id ${t.id}'].join(' · '),
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ItemView extends StatelessWidget {
  const _ItemView(this.item);
  final AgentItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (item) {
      UserSaid(:final text) => UserBubble(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ClaudeSaid(:final text) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ToolRan(:final summary, :final isError) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isError ? Icons.error_outline : Icons.bolt, size: 18, color: isError ? colors.danger : colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(summary,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: isError ? colors.danger : colors.muted)),
              ),
            ],
          ),
        ),
    };
  }
}
