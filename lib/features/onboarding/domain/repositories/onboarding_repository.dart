// FILE: features/onboarding/domain/repositories/onboarding_repository.dart
// Whether this phone has been through the welcome pages. They show once per install, before
// sign-in, like most apps. Implemented in data/repositories/onboarding_repository_impl.dart.

abstract interface class OnboardingRepository {
  /// Read at launch, without waiting.
  bool get seen;

  Future<void> markSeen();
}
