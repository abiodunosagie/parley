// FILE: app/router/app_router.dart
// All navigation, with GoRouter. Signed out: only the sign-in screen. Signed in: the four tabs in
// a StatefulShellRoute, so each tab keeps its own screen alive. The router re-checks the
// redirect every time the signed-in user changes, so signing in or out moves you automatically.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/conversation/presentation/screens/chat_screen.dart';
import '../../features/conversation/presentation/screens/look_screen.dart';
import '../../features/extract/presentation/screens/extract_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bumped on every sign-in / sign-out so GoRouter runs the redirect again.
  final authChanged = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => authChanged.value++);
  ref.onDispose(authChanged.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.chat,
    refreshListenable: authChanged,
    redirect: (context, state) {
      // The repository's current user is read synchronously, so a stream hiccup never bounces
      // a signed-in person back to the sign-in screen.
      final signedIn = ref.read(authRepositoryProvider).currentUser != null;
      final onSignIn = state.matchedLocation == AppRoutes.signIn;
      if (!signedIn) return onSignIn ? null : AppRoutes.signIn;
      if (onSignIn) return AppRoutes.chat;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (_, _) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.look,
                builder: (_, _) => const LookScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.extract,
                builder: (_, _) => const ExtractScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                builder: (_, _) => const TasksScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
