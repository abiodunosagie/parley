// FILE: features/conversation/presentation/widgets/claude_turn.dart
// One of Claude's replies: the "Parley" label, then the reply rendered as Markdown, or the typing
// dots while nothing has arrived yet. Long-press copies the whole reply.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../../core/theme/markdown_theme.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../domain/entities/chat_message.dart';
import 'typing_dots.dart';

/// One of Claude's replies.
class ClaudeTurn extends StatelessWidget {
  const ClaudeTurn(this.message, {super.key, required this.waiting});
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
                gptThemeData: markdownThemeOf(context),
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
