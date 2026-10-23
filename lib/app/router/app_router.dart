// FILE: app/router/app_router.dart
// All navigation, with GoRouter. At launch: the animated splash, then the welcome pages (once per
// install), then sign-in; app_gate.dart decides. Signed in: the five tabs in a
// StatefulShellRoute, so each tab keeps its own screen alive; Tools opens its three tools on top
// of its list. The router re-checks the gate whenever the launch finishes, the welcome pages are
// done, or the signed-in user changes, so every step moves on by itself.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/conversation/presentation/screens/chat_screen.dart';
import '../../features/conversation/presentation/screens/look_screen.dart';
import '../../features/conversation/presentation/screens/read_screen.dart';
import '../../features/extract/presentation/screens/extract_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/home/presentation/screens/tools_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/receipt/presentation/screens/receipt_screen.dart';
import '../../features/rewrite/presentation/screens/rewrite_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../launch/launch_controller.dart';
import '../launch/launch_screen.dart';
import 'app_gate.dart';
import 'app_routes.dart';

/// The launch, welcome and sign-in steps hand over with a soft cross-fade instead of a slide.
const _fadeDuration = Duration(milliseconds: 400);

Page<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _fadeDuration,
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

final routerProvider = Provider<GoRouter>((ref) {
  // Bumped whenever a step of the gate changes, so GoRouter runs the redirect again.
  final gateChanged = ValueNotifier<int>(0);
  ref.listen(currentUserProvider, (_, _) => gateChanged.value++);
  ref.listen(launchDoneProvider, (_, _) => gateChanged.value++);
  ref.listen(onboardingSeenProvider, (_, _) => gateChanged.value++);
  ref.onDispose(gateChanged.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.launch,
    refreshListenable: gateChanged,
    redirect: (context, state) => gateRedirect(
      location: state.matchedLocation,
      launchDone: ref.read(launchDoneProvider),
      onboardingSeen: ref.read(onboardingSeenProvider),
      // The repository's current user is read synchronously, so a stream hiccup never bounces
      // a signed-in person back to the sign-in screen.
      signedIn: ref.read(authRepositoryProvider).currentUser != null,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.launch,
        pageBuilder: (_, state) => _fade(state, const LaunchScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (_, state) => _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        pageBuilder: (_, state) => _fade(state, const SignInScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) =>
            _fade(state, HomeShell(navigationShell: shell)),
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
                path: AppRoutes.read,
                builder: (_, _) => const ReadScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tools,
                builder: (_, _) => const ToolsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.rewritePath,
                    builder: (_, _) => const RewriteScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.receiptsPath,
                    builder: (_, _) => const ReceiptScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.extractPath,
                    builder: (_, _) => const ExtractScreen(),
                  ),
                ],
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
