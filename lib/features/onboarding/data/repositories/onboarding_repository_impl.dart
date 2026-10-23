// FILE: features/onboarding/data/repositories/onboarding_repository_impl.dart
// The real OnboardingRepository: one flag in SharedPreferences. The version in the key lets a
// future redesign of the welcome pages show them once more.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/preferences_provider.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'parley.onboarding.v1.seen';

  @override
  bool get seen => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markSeen() => _prefs.setBool(_key, true);
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);
