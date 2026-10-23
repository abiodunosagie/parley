import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:parley/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';

void main() {
  test(
    'starts from what the phone remembers, and finishing saves once',
    () async {
      final store = MemoryOnboarding();
      final container = ProviderContainer(
        overrides: [onboardingRepositoryProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      expect(container.read(onboardingSeenProvider), isFalse);
      await container.read(onboardingSeenProvider.notifier).finish();
      await container.read(onboardingSeenProvider.notifier).finish();
      expect(container.read(onboardingSeenProvider), isTrue);
      expect(store.saves, 1);
    },
  );

  test('the real flag survives a restart of the app', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(OnboardingRepositoryImpl(prefs).seen, isFalse);
    await OnboardingRepositoryImpl(prefs).markSeen();
    // A new repository on the same storage, as after relaunching.
    expect(OnboardingRepositoryImpl(prefs).seen, isTrue);
  });
}
