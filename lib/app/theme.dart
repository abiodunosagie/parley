// FILE: app/theme.dart
// Colours, text styles and button shapes for light and dark mode.
// Screens never hard-code a colour: they call `context.colors.accent`, `context.colors.ink`, and so
// on. Change a colour here and the whole app follows.

import 'package:flutter/material.dart';

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
