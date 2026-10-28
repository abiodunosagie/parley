// FILE: core/session/own_api_key_provider.dart
// How the network layer finds the signed-in user's own Claude API key, without core knowing about
// the auth feature. main.dart overrides this provider with the auth feature's key store. Without
// an override there is no key, and every request uses Parley's shared key on the server.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns the signed-in user's own Anthropic key, or null to use Parley's shared key.
typedef OwnApiKey = Future<String?> Function();

final ownApiKeyProvider = Provider<OwnApiKey>(
  (ref) =>
      () async => null,
);
