// FILE: features/auth/data/repositories/api_key_repository_impl.dart
// The user's own Claude key, kept in the phone's secure storage: the iOS Keychain, or on Android
// values encrypted with a key held in the Android Keystore. On iOS the item is readable only on
// this device after its first unlock and never syncs to iCloud Keychain; Android backups are off
// for the app. The key is never written anywhere else and never logged.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/api_key_repository.dart';

class ApiKeyRepositoryImpl implements ApiKeyRepository {
  ApiKeyRepositoryImpl([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  final FlutterSecureStorage _storage;

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String _name(String userId) {
    if (!_safeId.hasMatch(userId)) throw ArgumentError.value(userId, 'userId');
    return 'anthropic_key_$userId';
  }

  @override
  Future<String?> read(String userId) async {
    try {
      return await _storage.read(key: _name(userId));
    } catch (e) {
      // A key that cannot be read (for example after Android drops its Keystore key) stops the
      // request instead of quietly spending Parley's shared key. Only the error's type is logged,
      // never what was stored.
      debugPrint('Parley: could not read the saved API key (${e.runtimeType})');
      throw const AppException(
        'Could not read your saved Claude key. Add it again or remove it under Account.',
      );
    }
  }

  @override
  Future<void> save(String userId, String key) =>
      _storage.write(key: _name(userId), value: key);

  @override
  Future<void> remove(String userId) => _storage.delete(key: _name(userId));
}

final apiKeyRepositoryProvider = Provider<ApiKeyRepository>(
  (ref) => ApiKeyRepositoryImpl(),
);
