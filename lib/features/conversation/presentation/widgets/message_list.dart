// FILE: features/conversation/presentation/widgets/message_list.dart
// Draws the conversation, newest at the bottom like WhatsApp: your messages on the right,
// Claude's replies full width with Markdown, and the "typing" dots while Claude thinks.

import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'claude_turn.dart';
import 'user_turn.dart';

/// The scrolling transcript shared by chat and vision.
///
/// How it behaves, and why:
/// - The list is built `reverse: true`, the way WhatsApp and Messenger do it. Index 0 is the
///   newest message and sits at the bottom, so the latest message stays in view when the
///   keyboard opens or a reply grows, with no manual scrolling code.
/// - Dragging the list dismisses the keyboard (`keyboardDismissBehavior.onDrag`).
/// - User turns sit on the right in a tinted bubble. Claude's turns run full width as rendered
///   Markdown, which reads best for long answers, lists and code.
/// - Long-press a Claude reply to copy it.
class MessageList extends StatelessWidget {
  const MessageList({super.key, required this.messages, required this.busy});

  final List<ChatMessage> messages;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        // Reverse lists count from the bottom, so flip the index back to the message order.
        final index = messages.length - 1 - i;
        final message = messages[index];
        final isLast = index == messages.length - 1;
        final waiting = busy && isLast && message.text.isEmpty;
        return message.fromUser
            ? UserTurn(message)
            : ClaudeTurn(message, waiting: waiting);
      },
    );
  }
}
