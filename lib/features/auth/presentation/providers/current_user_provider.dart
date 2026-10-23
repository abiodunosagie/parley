// FILE: features/auth/presentation/providers/current_user_provider.dart
// The signed-in user, or null. The router (app/router/app_router.dart) and every per-account
// screen rebuild when it changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  // Emit the user we already have straight away, so the app does not flash a loading screen.
  return Stream.value(repository.currentUser).asyncExpand((first) async* {
    yield first;
    yield* repository.watchUser();
  });
});
