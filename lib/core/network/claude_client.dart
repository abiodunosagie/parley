// FILE: core/network/claude_client.dart
// THE MOST IMPORTANT FILE FOR TALKING TO CLAUDE. Every Claude request goes through here.
// It POSTs {mode, model, messages} to the `claude` Supabase edge function with the user's
// session token. Chat and Look use `stream()` (text arrives bit by bit); Extract and Tasks use
// `request()` (one JSON answer). The Claude API key is NOT here: it lives on the server.
// Repositories in each feature's data/ folder call this; widgets never do.
// Read next: supabase/functions/claude/index.ts (the other end of this call).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../errors/app_exception.dart';
import '../models/claude_model.dart';
import '../session/access_token_provider.dart';
import 'cancel_token.dart';
import 'sse.dart';

/// What each screen asks the server for. Must match `MODES` in the edge function.
enum ClaudeMode { chat, vision, extract, agent }

/// The app's only door to Claude: the `claude` Supabase edge function. Every call carries the
/// signed-in user's session, which the server checks before it spends any credit.
class ClaudeClient {
  ClaudeClient(this._accessToken, {required this.endpoint, http.Client? client})
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
        throw AppException(
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
      throw AppException(_errorText(body, response.statusCode));
    }
    return _decode(body) ??
        (throw const AppException('The server sent an unreadable reply.'));
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
      throw const AppException(
        'No connection. Check your internet and try again.',
      );
    }
  }

  Future<String> _token({bool fresh = false}) => _accessToken(fresh: fresh);

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

final claudeClientProvider = Provider<ClaudeClient>(
  (ref) => ClaudeClient(
    ref.watch(accessTokenProvider),
    endpoint: Uri.parse('${Env.supabaseUrl}/functions/v1/claude'),
  ),
);
