// FILE: core/claude_api.dart
// THE MOST IMPORTANT FILE ON THE APP SIDE. Every Claude request goes through here.
// It POSTs {mode, model, messages} to the `claude` Supabase edge function with the user's
// session token. Chat and vision use `stream()` (text arrives bit by bit), extract and the agent
// use `request()` (one JSON answer). The Claude API key is NOT here: it lives on the server.
// Read next: supabase/functions/claude/index.ts (the other end of this call).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'claude_models.dart';
import 'env.dart';
import 'sse.dart';

/// What each screen asks the server for. Must match `MODES` in the edge function.
enum ClaudeMode { chat, vision, extract, agent }

/// A message the server refused or could not finish. [message] is safe to show as is: the
/// server only ever returns plain words, never internal details.
class ClaudeApiException implements Exception {
  const ClaudeApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Lets a screen stop a request that is still running (the Stop button, or starting over).
class CancelToken {
  final _completer = Completer<void>();
  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Returns a session token. `fresh: true` asks for a new one.
typedef AccessToken = Future<String> Function({bool fresh});

/// The app's only door to Claude: the `claude` Supabase edge function. Every call carries the
/// signed-in user's session, which the server checks before it spends any credit.
class ClaudeApi {
  ClaudeApi(this._accessToken, {required this.endpoint, http.Client? client})
    : _client = client ?? http.Client();

  final AccessToken _accessToken;
  final Uri endpoint;
  final http.Client _client;

  /// Streams Claude's reply as it is written. Used by chat and vision.
  Stream<StreamEvent> stream({
    required ClaudeMode mode,
    required ClaudeModel model,
    required List<Map<String, dynamic>> messages,
    CancelToken? cancel,
  }) async* {
    try {
      final response = await _send(mode, model, messages, cancel);
      if (response.statusCode != 200) {
        throw ClaudeApiException(
          _errorText(
            await response.stream.bytesToString(),
            response.statusCode,
          ),
        );
      }
      yield* parseSse(response.stream);
    } on http.RequestAbortedException {
      // The user tapped Stop: end the stream quietly, keeping what already arrived.
    }
  }

  /// One finished JSON response. Used by extraction and the agent.
  Future<Map<String, dynamic>> request({
    required ClaudeMode mode,
    required ClaudeModel model,
    required List<Map<String, dynamic>> messages,
    CancelToken? cancel,
  }) async {
    final response = await _send(mode, model, messages, cancel);
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw ClaudeApiException(_errorText(body, response.statusCode));
    }
    return _decode(body) ??
        (throw const ClaudeApiException(
          'The server sent an unreadable reply.',
        ));
  }

  /// Sends once, and once more with a refreshed session if the server rejected the old one
  /// (a session the phone still thinks is valid can be revoked on the server).
  Future<http.StreamedResponse> _send(
    ClaudeMode mode,
    ClaudeModel model,
    List<Map<String, dynamic>> messages,
    CancelToken? cancel,
  ) async {
    final body = jsonEncode({
      'mode': mode.name,
      'model': model.id,
      'messages': messages,
    });
    var response = await _post(body, await _token(), cancel);
    if (response.statusCode == 401) {
      await response.stream.drain<void>();
      response = await _post(body, await _token(fresh: true), cancel);
    }
    return response;
  }

  Future<http.StreamedResponse> _post(
    String body,
    String token,
    CancelToken? cancel,
  ) async {
    final request =
        http.AbortableRequest(
            'POST',
            endpoint,
            abortTrigger: cancel?.whenCancelled,
          )
          ..headers.addAll({
            'Authorization': 'Bearer $token',
            'apikey': Env.supabasePublishableKey,
            'Content-Type': 'application/json',
          })
          ..body = body;
    try {
      return await _client.send(request);
    } on http.RequestAbortedException {
      // A subclass of ClientException: let callers see it as a cancel, not as "no connection".
      rethrow;
    } on http.ClientException {
      throw const ClaudeApiException(
        'No connection. Check your internet and try again.',
      );
    }
  }

  Future<String> _token({bool fresh = false}) async {
    try {
      return await _accessToken(fresh: fresh);
    } on AuthException catch (e) {
      debugPrint('Parley session refresh failed: ${e.message}');
      throw const ClaudeApiException('Your session ended. Sign in again.');
    }
  }

  String _errorText(String body, int status) =>
      _decode(body)?['error'] as String? ??
      'Something went wrong ($status). Try again.';

  Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }
}

/// The signed-in user's token. `fresh` asks Supabase for a new one when the server rejected the
/// old one; if that fails too the user is signed out and lands back on the sign-in screen.
Future<String> supabaseAccessToken({bool fresh = false}) async {
  final auth = Supabase.instance.client.auth;
  var session = auth.currentSession;
  if (session == null) throw const ClaudeApiException('Sign in to use Parley.');
  if (fresh || session.isExpired) {
    try {
      session = (await auth.refreshSession()).session;
    } on AuthException {
      await auth.signOut(scope: SignOutScope.local);
      throw const ClaudeApiException('Your session ended. Sign in again.');
    }
  }
  return session?.accessToken ??
      (throw const ClaudeApiException('Sign in to use Parley.'));
}

final claudeApiProvider = Provider<ClaudeApi>(
  (ref) => ClaudeApi(
    supabaseAccessToken,
    endpoint: Uri.parse('${Env.supabaseUrl}/functions/v1/claude'),
  ),
);

/// The words a screen shows when a request ends badly.
String noticeFor(Object error, {required bool cancelled, required String tag}) {
  if (error is ClaudeApiException) return error.message;
  if (cancelled) return 'Stopped.';
  debugPrint('Parley $tag error: $error');
  return 'Something went wrong. Try again.';
}

/// The words the app shows when a reply ends for a reason other than finishing normally.
String? stopReasonNote(String? stopReason) => switch (stopReason) {
  'refusal' => 'Claude declined this request. Try asking a different way.',
  'max_tokens' => 'The reply hit its length limit and was cut short.',
  _ => null,
};
