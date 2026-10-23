// FILE: features/onboarding/presentation/widgets/exchange.dart
// The pieces of a real Parley conversation, drawn the way Chat and Tasks draw them (your message
// on the right in the shared bubble, Parley's reply full width under its name), so the welcome
// pages show the product rather than a picture of one. Each line arrives in turn.

import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/parley_colors.dart';
import '../../../../core/widgets/user_bubble.dart';
import '../../../../core/widgets/reveal.dart';

Duration _step(int i) => Duration(milliseconds: 180 + i * 320);

/// A conversation that plays in, one line after another.
class Exchange extends StatelessWidget {
  const Exchange({super.key, required this.lines});
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, line) in lines.indexed)
        Reveal(delay: _step(i), child: line),
    ],
  );
}

class YouSaid extends StatelessWidget {
  const YouSaid(this.text, {super.key, this.attachment});
  final String text;

  /// A file name shown above the text, as Read does for a PDF.
  final String? attachment;

  @override
  Widget build(BuildContext context) => UserBubble(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (attachment != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    attachment!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

/// Parley's name, as it heads every reply in Chat.
class ParleyLabel extends StatelessWidget {
  const ParleyLabel({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Text(
      'Parley',
      // The same style as the name over every reply in Chat (claude_turn.dart).
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.colors.accent, fontWeight: FontWeight.w700),
    ),
  );
}

class ParleySaid extends StatelessWidget {
  const ParleySaid(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyLarge);
}

/// A muted step line under Parley's name: a search it ran, or a tool it used.
class StepLine extends StatelessWidget {
  const StepLine(this.text, {super.key, required this.icon, this.mono = false});
  final String text;
  final IconData icon;

  /// Tool calls read as code, like the lightning lines in Tasks.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: mono ? context.colors.accent : muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontFamily: mono ? 'monospace' : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// A cited source under a reply, as Chat and Read list them.
class SourceLine extends StatelessWidget {
  const SourceLine({super.key, required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.code, borderRadius: kRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1',
            style: TextStyle(color: colors.accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
