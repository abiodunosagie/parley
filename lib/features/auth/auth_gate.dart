// FILE: features/auth/auth_gate.dart
// Decides what to show: the sign-in screen when nobody is signed in, the tabs when
// someone is. When the account changes it clears the old account's conversations.
// Read next: lib/app/home_shell.dart, then lib/features/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/home_shell.dart';
import '../agent/agent_controller.dart';
import '../conversation/conversation.dart';
import '../extract/extract_controller.dart';
import 'auth_controller.dart';
import 'auth_screen.dart';

/// Shows the sign-in screen or the app, following the Supabase session.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A different account (or none) must never see the previous one's conversations.
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.value?.id == next.value?.id) return;
      ref
        ..invalidate(chatProvider)
        ..invalidate(visionProvider)
        ..invalidate(extractProvider)
        ..invalidate(agentProvider);
    });

    final user = ref.watch(currentUserProvider);
    return user.when(
      data: (user) => user == null ? const AuthScreen() : const HomeShell(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const AuthScreen(),
    );
  }
}
