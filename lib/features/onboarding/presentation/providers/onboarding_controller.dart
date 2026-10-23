// FILE: features/onboarding/presentation/providers/onboarding_controller.dart
// True once the welcome pages are done (finished or skipped). The router listens to it, so
// finishing moves straight on to sign-in.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_log.dart';
import '../../data/repositories/onboarding_repository_impl.dart';

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingRepositoryProvider).seen;

  /// Moves on at once; the flag is saved in the background. If saving fails the pages simply
  /// show again next launch, which is better than holding the person here.
  Future<void> finish() async {
    if (state) return;
    state = true;
    try {
      await ref.read(onboardingRepositoryProvider).markSeen();
    } catch (e) {
      reportError(e, cancelled: false, tag: 'onboarding');
    }
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
