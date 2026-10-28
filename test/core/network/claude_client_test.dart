import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parley/core/errors/app_exception.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/claude_client.dart';
import 'package:parley/core/network/sse.dart';

final _endpoint = Uri.parse('https://example.supabase.co/functions/v1/claude');

ClaudeClient _api(
  MockClient client, {
  List<bool>? tokenCalls,
  String? ownKey,
}) => ClaudeClient(
  ({bool fresh = false}) async {
    tokenCalls?.add(fresh);
    return fresh ? 'new-token' : 'old-token';
  },
  endpoint: _endpoint,
  ownKey: () async => ownKey,
  client: client,
);

void main() {
  group('ClaudeClient', () {
    test('shows the server error text as is', () async {
      final api = _api(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'error': 'Slow down a little.'}), 429),
        ),
      );
      expect(
        () => api.request(
          mode: ClaudeMode.extract,
          model: ClaudeModel.haiku,
          messages: const [],
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'Slow down a little.',
          ),
        ),
      );
    });

    test('retries once with a refreshed token after a 401', () async {
      final tokens = <bool>[];
      final seen = <String?>[];
      final api = _api(
        MockClient((request) async {
          seen.add(request.headers['Authorization']);
          return seen.length == 1
              ? http.Response('{"error":"expired"}', 401)
              : http.Response('{"fields":{}}', 200);
        }),
        tokenCalls: tokens,
      );
      final json = await api.request(
        mode: ClaudeMode.extract,
        model: ClaudeModel.haiku,
        messages: const [],
      );
      expect(json, {'fields': <String, dynamic>{}});
      expect(tokens, [false, true]);
      expect(seen, ['Bearer old-token', 'Bearer new-token']);
    });

    test('sends mode, model id and messages', () async {
      late Map<String, dynamic> body;
      final api = _api(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }),
      );
      await api.request(
        mode: ClaudeMode.agent,
        model: ClaudeModel.sonnet,
        messages: [
          {'role': 'user', 'content': 'Hi'},
        ],
      );
      expect(body, {
        'mode': 'agent',
        'model': 'claude-sonnet-5-5',
        'messages': [
          {'role': 'user', 'content': 'Hi'},
        ],
      });
    });

    test('sends the user\'s own key in the body, never a header', () async {
      final seen = <String?>[];
      late Map<String, String> headers;
      final api = _api(
        MockClient((request) async {
          headers = request.headers;
          seen.add((jsonDecode(request.body) as Map)['api_key'] as String?);
          return http.Response('{}', 200);
        }),
        ownKey: 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz',
      );
      await api.request(
        mode: ClaudeMode.extract,
        model: ClaudeModel.haiku,
        messages: const [],
      );
      expect(seen, ['sk-ant-api03-abcdefghijklmnopqrstuvwxyz']);
      expect(headers.values.any((v) => v.contains('sk-ant-')), isFalse);
    });

    test('sends no key without a saved key', () async {
      late Map<String, dynamic> body;
      final api = _api(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }),
      );
      await api.request(
        mode: ClaudeMode.extract,
        model: ClaudeModel.haiku,
        messages: const [],
      );
      expect(body.containsKey('api_key'), isFalse);
    });

    test('a rejected own key is shown once, with no session retry', () async {
      final tokens = <bool>[];
      var calls = 0;
      final api = _api(
        MockClient((_) async {
          calls++;
          return http.Response(
            jsonEncode({
              'error':
                  'Claude did not accept your API key. Check it under Account.',
            }),
            403,
          );
        }),
        tokenCalls: tokens,
        ownKey: 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz',
      );
      await expectLater(
        api.request(
          mode: ClaudeMode.extract,
          model: ClaudeModel.haiku,
          messages: const [],
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('API key'),
          ),
        ),
      );
      expect(calls, 1);
      expect(tokens, [false]);
    });

    test('streams text deltas', () async {
      final api = _api(
        MockClient(
          (_) async => http.Response(
            'data: {"type":"text","text":"Hi"}\n\ndata: {"type":"done","stop_reason":"end_turn"}\n\n',
            200,
          ),
        ),
      );
      final events = await api
          .stream(
            mode: ClaudeMode.chat,
            model: ClaudeModel.opus,
            messages: const [],
          )
          .toList();
      expect((events.first as TextDelta).text, 'Hi');
      expect((events.last as StreamDone).stopReason, 'end_turn');
    });
  });
}
