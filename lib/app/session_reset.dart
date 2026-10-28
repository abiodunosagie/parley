// FILE: app/session_reset.dart
// When the signed-in account changes (sign out, a session that ends, another person signs in), every
// conversation from the previous account is cleared, so nobody ever sees someone else's chats, the
// previous account's own Claude key is removed from the phone so nobody else can spend it, and any
// open sheet or dialog is closed so it cannot sit on top of the sign-in screen.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/error_log.dart';
import '../features/auth/data/repositories/api_key_repository_impl.dart';
import '../features/auth/presentation/providers/current_user_provider.dart';
import '../features/conversation/presentation/providers/conversation_controller.dart';
import '../features/conversation/presentation/providers/look_controller.dart';
import '../features/conversation/presentation/providers/read_controller.dart';
import '../features/extract/presentation/providers/extract_controller.dart';
import '../features/receipt/presentation/providers/receipt_controller.dart';
import '../features/rewrite/presentation/providers/rewrite_controller.dart';
import '../features/tasks/presentation/providers/agent_controller.dart';
import 'router/app_router.dart';

class SessionReset extends ConsumerWidget {
  const SessionReset({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProvider, (previous, next) {
      final previousId = previous?.value?.id;
      if (previousId == next.value?.id) return;
      if (previousId != null) {
        ref
            .read(apiKeyRepositoryProvider)
            .remove(previousId)
            .catchError(
              (Object e) => reportError(e, cancelled: false, tag: 'api key'),
            );
      }
      // Pageless routes (bottom sheets, dialogs) are not managed by the router, so close them here.
      ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentState
          ?.popUntil((route) => route.settings is Page);
      ref
        ..invalidate(chatControllerProvider)
        ..invalidate(lookControllerProvider)
        ..invalidate(readControllerProvider)
        ..invalidate(extractControllerProvider)
        ..invalidate(receiptControllerProvider)
        ..invalidate(rewriteControllerProvider)
        ..invalidate(agentControllerProvider);
    });
    return child;
  }
}
