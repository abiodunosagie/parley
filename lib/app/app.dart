// FILE: app/app.dart
// The app widget: light and dark themes, the router, tap-to-dismiss for the keyboard on every
// screen, and the per-account reset.
// Read next: app/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/keyboard_dismiss.dart';
import 'router/app_router.dart';
import 'session_reset.dart';

class ParleyApp extends ConsumerWidget {
  const ParleyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Parley',
      debugShowCheckedModeBanner: false,
      theme: parleyTheme(Brightness.light),
      darkTheme: parleyTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => SessionReset(
        child: KeyboardDismiss(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
