// FILE: app/theme.dart
// Colours, text styles and button shapes for light and dark mode.
// Screens never hard-code a colour: they call `context.colors.accent`, `context.colors.ink`, and so
// on. Change a colour here and the whole app follows.

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Corner radius for every box, button and bubble. Rounded, never a pill.
const kRadius = BorderRadius.all(Radius.circular(12));

/// Parley's colours, one set for light and one for dark. Screens read these through
/// `context.colors`, never hard-coded hex values.
@immutable
class ParleyColors extends ThemeExtension<ParleyColors> {
  const ParleyColors({
    required this.background,
    required this.ink,
    required this.muted,
    required this.line,
    required this.userBubble,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
    required this.code,
  });

  final Color background;
  final Color ink;
  final Color muted;
  final Color line;
  final Color userBubble;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color danger;

  /// Background of code blocks in Claude's replies.
  final Color code;

  static const light = ParleyColors(
    background: Color(0xFFFFFFFF),
    ink: Color(0xFF15130F),
    muted: Color(0xFF6B675F),
    line: Color(0xFFE7E4DD),
    userBubble: Color(0xFFF1EFEA),
    accent: Color(0xFF1F6F54),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE3F0EA),
    danger: Color(0xFFB3261E),
    code: Color(0xFFF6F5F2),
  );

  static const dark = ParleyColors(
    background: Color(0xFF0F0E0C),
    ink: Color(0xFFF2EFE8),
    muted: Color(0xFFA29D93),
    line: Color(0xFF2C2A26),
    userBubble: Color(0xFF221F1B),
    accent: Color(0xFF5CC79C),
    onAccent: Color(0xFF0F0E0C),
    accentSoft: Color(0xFF173328),
    danger: Color(0xFFF2B8B5),
    code: Color(0xFF1A1916),
  );

  @override
  ParleyColors copyWith({
    Color? background,
    Color? ink,
    Color? muted,
    Color? line,
    Color? userBubble,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? danger,
    Color? code,
  }) => ParleyColors(
    background: background ?? this.background,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    userBubble: userBubble ?? this.userBubble,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSoft: accentSoft ?? this.accentSoft,
    danger: danger ?? this.danger,
    code: code ?? this.code,
  );

  @override
  ParleyColors lerp(ParleyColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return ParleyColors(
      background: mix(background, other.background),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      userBubble: mix(userBubble, other.userBubble),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      danger: mix(danger, other.danger),
      code: mix(code, other.code),
    );
  }
}

extension ParleyColorsX on BuildContext {
  ParleyColors get colors => Theme.of(this).extension<ParleyColors>()!;
}

ThemeData parleyTheme(Brightness brightness) {
  final c = brightness == Brightness.light
      ? ParleyColors.light
      : ParleyColors.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    surface: c.background,
    onSurface: c.ink,
    error: c.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    dividerColor: c.line,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: c.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: c.ink),
      bodyMedium: TextStyle(fontSize: 15, height: 1.4, color: c.muted),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: c.muted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: c.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.background,
      indicatorColor: c.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: c.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.userBubble,
      border: const OutlineInputBorder(
        borderRadius: kRadius,
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: c.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(borderRadius: kRadius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: c.ink,
        side: BorderSide(color: c.line),
        shape: const RoundedRectangleBorder(borderRadius: kRadius),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Colours for Claude's Markdown replies. gpt_markdown falls back to its own light defaults for
/// headings and code blocks, which turned dark-mode headings dark-on-dark and code blocks lavender,
/// so every colour it draws with is set here from Parley's palette.
GptMarkdownThemeData parleyMarkdownTheme(BuildContext context) {
  final c = context.colors;
  final brightness = Theme.of(context).brightness;
  TextStyle heading(double size) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: c.ink,
  );
  return GptMarkdownThemeData(
    brightness: brightness,
    h1: heading(24),
    h2: heading(21),
    h3: heading(18),
    h4: heading(17),
    h5: heading(16),
    h6: heading(15),
    linkColor: c.accent,
    linkHoverColor: c.accent,
    hrLineColor: c.line,
    highlightColor: c.userBubble,
    styleSheet: GptMarkdownStyleSheet(
      codeBlock: CodeBlockStyle(
        backgroundColor: c.code,
        borderColor: c.line,
        textColor: c.ink,
        borderRadius: const Radius.circular(12),
        // The package draws these two from its own light palette in dark mode; long-press on a
        // reply copies the whole answer instead.
        showLanguageLabel: false,
        showCopyButton: false,
      ),
    ),
  );
}
