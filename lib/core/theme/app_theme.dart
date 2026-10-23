// FILE: core/theme/app_theme.dart
// The Material theme for light and dark mode: text styles, app bar, inputs and button shapes,
// all built from the palette in parley_colors.dart.

import 'package:flutter/material.dart';

import 'dimens.dart';
import 'parley_colors.dart';

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
        minimumSize: const Size.fromHeight(kButtonHeight),
        shape: const RoundedRectangleBorder(borderRadius: kRadius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
        foregroundColor: c.ink,
        side: BorderSide(color: c.line),
        shape: const RoundedRectangleBorder(borderRadius: kRadius),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
