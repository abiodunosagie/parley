// FILE: features/conversation/presentation/widgets/claude_turn.dart
// One of Claude's replies: the "Parley" label, Claude's reasoning (folded once the answer starts),
// the web searches it ran, the reply rendered as Markdown (or the typing dots while nothing has
// arrived yet), and the sources it cited. Long-press copies the reply text.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../../../core/theme/markdown_theme.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/reasoning_panel.dart';
import '../../domain/entities/chat_message.dart';
import 'search_lines.dart';
import 'source_list.dart';
import 'typing_dots.dart';

/// One of Claude's replies.
class ClaudeTurn extends StatelessWidget {
  const ClaudeTurn(this.message, {super.key, required this.waiting});
  final ChatMessage message;

  /// True while the reply has been requested but nothing has arrived yet.
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
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.accent, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (message.thinking.isNotEmpty)
              ReasoningPanel(
                thinking: message.thinking,
                answering: message.text.isNotEmpty,
              ),
            if (message.searches.isNotEmpty) SearchLines(message.searches),
            if (waiting)
              const TypingDots()
            else if (message.text.isNotEmpty)
              GptMarkdownTheme(
                gptThemeData: markdownThemeOf(context),
                child: GptMarkdown(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            if (message.sources.isNotEmpty) SourceList(message.sources),
          ],
        ),
      ),
    );
  }
}
