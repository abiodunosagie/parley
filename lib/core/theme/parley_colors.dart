// FILE: core/theme/parley_colors.dart
// Parley's colour palette, one set for light mode and one for dark mode, plus `context.colors`.
// Widgets never hard-code a colour: they read `context.colors.accent`, `context.colors.ink`, and
// so on. Change a value here and the whole app follows.

import 'package:flutter/material.dart';

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
