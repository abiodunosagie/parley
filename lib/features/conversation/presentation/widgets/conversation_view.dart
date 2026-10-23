// FILE: features/conversation/presentation/widgets/conversation_view.dart
// The body Chat, Look and Read share: the conversation (or what to show while it is empty), the
// note under it, an optional control above the composer (Chat's web search switch), and the
// composer. Screens only decide the empty state, the hint and that control.

import 'package:flutter/material.dart';

import '../../../../core/widgets/composer.dart';
import '../../../../core/widgets/notice.dart';
import '../providers/conversation_state.dart';
import 'message_list.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    super.key,
    required this.state,
    required this.onSend,
    required this.onStop,
    required this.empty,
    this.hint = 'Message Parley',
    this.aboveComposer,
  });

  final ConversationState state;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  /// Shown instead of the message list before the first message.
  final Widget empty;
  final String hint;
  final Widget? aboveComposer;

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
        ?aboveComposer,
        Composer(busy: state.busy, onSend: onSend, onStop: onStop, hint: hint),
      ],
    );
  }
}
