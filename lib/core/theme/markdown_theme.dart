// FILE: core/theme/markdown_theme.dart
// How Claude's Markdown replies look: headings, links, dividers and code blocks.
// gpt_markdown otherwise falls back to its own light palette, which drew dark-mode headings dark
// on dark and code blocks lavender. One instance per brightness is built once and reused, because
// a new instance on every rebuild makes the package re-parse finished text on every streamed token.

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'dimens.dart';
import 'parley_colors.dart';

/// Heading sizes h1 to h6. The small steps keep long answers calm on a phone screen.
const _headingSizes = [24.0, 21.0, 18.0, 17.0, 16.0, 15.0];

final _light = _build(Brightness.light, ParleyColors.light);
final _dark = _build(Brightness.dark, ParleyColors.dark);

/// The Markdown theme for the current brightness.
GptMarkdownThemeData markdownThemeOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _dark : _light;

GptMarkdownThemeData _build(Brightness brightness, ParleyColors c) {
  TextStyle heading(int level) => TextStyle(
    fontSize: _headingSizes[level - 1],
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: c.ink,
  );
  return GptMarkdownThemeData(
    brightness: brightness,
    h1: heading(1),
    h2: heading(2),
    h3: heading(3),
    h4: heading(4),
    h5: heading(5),
    h6: heading(6),
    linkColor: c.accent,
    linkHoverColor: c.accent,
    hrLineColor: c.line,
    highlightColor: c.userBubble,
    styleSheet: GptMarkdownStyleSheet(
      codeBlock: CodeBlockStyle(
        backgroundColor: c.code,
        borderColor: c.line,
        textColor: c.ink,
        borderRadius: kCornerRadius,
        // The package draws these two from its own light palette in dark mode. Long-press on a
        // reply copies the whole answer instead (see claude_turn.dart).
        showLanguageLabel: false,
        showCopyButton: false,
      ),
    ),
  );
}
