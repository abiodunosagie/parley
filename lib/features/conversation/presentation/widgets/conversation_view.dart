// FILE: features/conversation/presentation/widgets/conversation_view.dart
// The body both Chat and Look share: the conversation (or what to show while it is empty), the
// note under it, and the composer. Screens only decide the empty state and the hint.

import 'package:flutter/material.dart';

import '../../../../core/widgets/composer.dart';
import '../../../../core/widgets/notice_line.dart';
import '../providers/conversation_controller.dart';
import '../providers/conversation_state.dart';
import 'message_list.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.state,
    required this.controller,
    required this.empty,
    this.hint = 'Message Parley',
  });

  final ConversationState state;
  final ConversationController controller;

  /// Shown instead of the message list before the first message.
  final Widget empty;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: state.isEmpty
              ? empty
              : MessageList(messages: state.messages, busy: state.busy),
        ),
        if (state.notice != null) Notice(state.notice!),
        Composer(
          busy: state.busy,
          onSend: controller.send,
          onStop: controller.stop,
          hint: hint,
        ),
      ],
    );
  }
}
