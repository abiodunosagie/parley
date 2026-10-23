// FILE: core/storage/preferences_provider.dart
// The phone's small key-value store, opened once in main.dart before the first frame so anything
// that must be known at launch (has onboarding been seen?) is read without waiting.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider is overridden in main.dart. Tests that '
    'build ParleyApp override onboardingRepositoryProvider instead.',
  ),
);
