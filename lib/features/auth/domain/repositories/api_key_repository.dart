// FILE: features/auth/domain/repositories/api_key_repository.dart
// Where a user's own Claude API key is kept on the phone. One key per account, so another account
// signed in on the same phone never sees or uses it. The secure-storage version is in
// data/repositories/api_key_repository_impl.dart; tests can swap in a fake.

abstract interface class ApiKeyRepository {
  /// The key saved for [userId], or null when there is none. Throws AppException when a saved key
  /// cannot be read.
  Future<String?> read(String userId);

  Future<void> save(String userId, String key);

  /// Forgets the key for [userId]. Doing nothing when there is no key.
  Future<void> remove(String userId);
}
