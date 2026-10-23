// FILE: features/conversation/message_list.dart
// Draws the conversation: your messages on the right, Claude's replies full width with
// Markdown, and the three "typing" dots while Claude thinks.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../app/theme.dart';
import '../../shared/blocks.dart';
import 'conversation.dart';

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
            ? _UserTurn(message)
            : _ClaudeTurn(message, waiting: waiting);
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
                child: Image.memory(
                  photo.bytes,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ClaudeTurn extends StatelessWidget {
  const _ClaudeTurn(this.message, {required this.waiting});
  final ChatMessage message;

  /// True while the reply has been requested but no text has arrived yet.
  final bool waiting;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onLongPress: message.text.isEmpty ? null : () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parley',
              style: TextStyle(
                color: colors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (waiting)
              const TypingDots()
            else
              GptMarkdownTheme(
                gptThemeData: parleyMarkdownTheme(context),
                child: GptMarkdown(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that pulse in turn while Claude is thinking, like the "typing..." indicator in a
/// messaging app.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.muted;
    return Semantics(
      label: 'Parley is thinking',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Opacity(
                  // Each dot peaks a third of a cycle after the one before it.
                  opacity:
                      0.3 + 0.7 * _pulse((_controller.value - i * 0.2) % 1),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 0 to 1 and back to 0 over the first half of the cycle, then rests at 0.
  double _pulse(double t) => t < 0.5 ? 1 - (2 * t - 0.5).abs() * 2 : 0;
}
