// FILE: features/auth/presentation/providers/current_user_provider.dart
// The signed-in user, or null. The router (app/router/app_router.dart) and every per-account
// screen rebuild when it changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';

final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  // The user we already have comes first, so the app never flashes a loading screen.
  yield repository.currentUser;
  // A token refresh that fails offline arrives as a stream error. It does not mean the user
  // signed out, so it is skipped instead of clearing the signed-in user.
  yield* repository.watchUser().handleError((Object _) {});
});

/// Just the signed-in user's id, so per-account lists rebuild only when the account changes.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider.select((user) => user.value?.id)),
);
