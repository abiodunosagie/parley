// FILE: core/session/access_token_provider.dart
// How the network layer gets the signed-in user's token, without core knowing about the auth
// feature. main.dart overrides this provider with the auth repository; tests override it with a fake.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a session token. `fresh: true` asks for a new one after the server rejected the old.
typedef AccessToken = Future<String> Function({bool fresh});

final accessTokenProvider = Provider<AccessToken>(
  (ref) => throw UnimplementedError(
    'accessTokenProvider is overridden in main.dart',
  ),
);
