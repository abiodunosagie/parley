// FILE: features/conversation/presentation/widgets/history_button.dart
// The History button in the Chat, Look and Read app bars: lists that feature's saved
// conversations, opens one, or deletes one.

import 'package:flutter/material.dart';

import '../../../../core/widgets/history_sheet.dart';
import '../../domain/entities/conversation_kind.dart';
import '../providers/conversation_controller.dart';
import '../providers/conversation_history_provider.dart';

class ConversationHistoryButton extends StatelessWidget {
  const ConversationHistoryButton({
    super.key,
    required this.kind,
    required this.controller,
  });

  final ConversationKind kind;
  final ConversationController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'History',
      icon: const Icon(Icons.history),
      onPressed: () => showHistorySheet(
        context,
        entries: conversationHistoryProvider(kind),
        onOpen: controller.open,
        onDelete: controller.deleteSaved,
        empty: 'Your conversations appear here after the first reply.',
      ),
    );
  }
}
