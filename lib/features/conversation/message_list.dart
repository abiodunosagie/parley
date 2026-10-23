import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../app/theme.dart';
import '../../shared/blocks.dart';
import 'conversation.dart';

/// The scrolling transcript shared by chat and vision. User turns sit right in a tinted block;
/// Claude's turns run full width as rendered Markdown, the way long answers read best on a phone.
class MessageList extends StatefulWidget {
  const MessageList({super.key, required this.messages, required this.busy});

  final List<ChatMessage> messages;
  final bool busy;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(MessageList old) {
    super.didUpdateWidget(old);
    // Follow the reply as it streams in, unless the user scrolled up to read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent - position.pixels < 120) _scroll.jumpTo(position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: widget.messages.length,
      itemBuilder: (context, i) {
        final message = widget.messages[i];
        final waiting = widget.busy && i == widget.messages.length - 1 && message.text.isEmpty;
        return message.fromUser ? _UserTurn(message) : _ClaudeTurn(message, waiting: waiting);
      },
    );
  }
}

class _UserTurn extends StatelessWidget {
  const _UserTurn(this.message);
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final photo = message.attachment;
    return UserBubble(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(photo.bytes, height: 140, fit: BoxFit.cover),
              ),
            ),
          SelectableText(message.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ClaudeTurn extends StatelessWidget {
  const _ClaudeTurn(this.message, {required this.waiting});
  final ChatMessage message;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parley', style: TextStyle(color: colors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (waiting)
            Text('Thinking...', style: TextStyle(color: colors.muted, fontStyle: FontStyle.italic))
          else
            GptMarkdown(message.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
