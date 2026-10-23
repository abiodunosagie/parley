// FILE: app/session_reset.dart
// When the signed-in account changes (sign out, another person signs in), every conversation from
// the previous account is cleared, so nobody ever sees someone else's chats.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/current_user_provider.dart';
import '../features/conversation/presentation/providers/conversation_controller.dart';
import '../features/extract/presentation/providers/extract_controller.dart';
import '../features/tasks/presentation/providers/agent_controller.dart';

class SessionReset extends ConsumerWidget {
  const SessionReset({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.value?.id == next.value?.id) return;
      ref
        ..invalidate(chatControllerProvider)
        ..invalidate(lookControllerProvider)
        ..invalidate(extractControllerProvider)
        ..invalidate(agentControllerProvider);
    });
    return child;
  }
}
