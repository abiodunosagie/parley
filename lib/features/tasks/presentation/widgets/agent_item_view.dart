// FILE: features/tasks/presentation/widgets/agent_item_view.dart
// One line of the Tasks conversation: your message, Claude's answer, or a tool Claude ran (a
// lightning line, red when the tool refused).

import 'package:flutter/material.dart';

import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/user_bubble.dart';
import '../../domain/entities/agent_item.dart';

class AgentItemView extends StatelessWidget {
  const AgentItemView(this.item, {super.key});
  final AgentItem item;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return switch (item) {
      UserSaid(:final text) => UserBubble(child: Text(text, style: body)),
      ClaudeSaid(:final text) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(text, style: body),
      ),
      ToolRan(:final summary, :final isError) => _ToolLine(
        summary: summary,
        isError: isError,
      ),
    };
  }
}

class _ToolLine extends StatelessWidget {
  const _ToolLine({required this.summary, required this.isError});
  final String summary;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.bolt,
            size: 18,
            color: isError ? colors.danger : colors.accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: isError ? colors.danger : colors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
