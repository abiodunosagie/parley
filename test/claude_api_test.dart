import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parley/core/claude_api.dart';
import 'package:parley/core/claude_models.dart';
import 'package:parley/core/sse.dart';
import 'package:parley/features/agent/agent_controller.dart';
import 'package:parley/features/auth/auth_controller.dart';

final _endpoint = Uri.parse('https://example.supabase.co/functions/v1/claude');

ClaudeApi _api(MockClient client, {List<bool>? tokenCalls}) => ClaudeApi(
  ({bool fresh = false}) async {
    tokenCalls?.add(fresh);
    return fresh ? 'new-token' : 'old-token';
  },
  endpoint: _endpoint,
  client: client,
);

void main() {
  group('ClaudeApi', () {
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
          isA<ClaudeApiException>().having(
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

  group('AgentController', () {
    late List<Map<String, dynamic>> replies;
    late List<List<dynamic>> sentTranscripts;

    ProviderContainer container() {
      sentTranscripts = [];
      final client = MockClient((request) async {
        sentTranscripts.add(
          (jsonDecode(request.body) as Map<String, dynamic>)['messages']
              as List,
        );
        return http.Response(jsonEncode(replies.removeAt(0)), 200);
      });
      final c = ProviderContainer(
        overrides: [
          claudeApiProvider.overrideWithValue(_api(client)),
          // No signed-in user: tasks stay in memory, nothing touches SharedPreferences.
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'runs the tool, sends the result back, and keeps the finished turn',
      () async {
        replies = [
          {
            'stop_reason': 'tool_use',
            'content': [
              {'type': 'thinking', 'thinking': '', 'signature': 'sig'},
              {
                'type': 'tool_use',
                'id': 'call1',
                'name': 'add_task',
                'input': {'title': 'Milk', 'due_date': '', 'priority': 'low'},
              },
            ],
          },
          {
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': 'Added milk.'},
            ],
          },
        ];
        final c = container();
        await c.read(agentProvider.notifier).send('Add milk');

        final second = sentTranscripts[1];
        expect(second, hasLength(3));
        expect(((second[1] as Map)['content'] as List).first, {
          'type': 'thinking',
          'thinking': '',
          'signature': 'sig',
        });
        final result = ((second[2] as Map)['content'] as List).single as Map;
        expect(result['tool_use_id'], 'call1');
        expect(result.containsKey('is_error'), isFalse);

        final state = c.read(agentProvider);
        expect(state.busy, isFalse);
        expect(state.items.whereType<ClaudeSaid>().single.text, 'Added milk.');
      },
    );

    test(
      'a reply cut off mid tool call is rolled back, so the next send is clean',
      () async {
        replies = [
          {
            'stop_reason': 'max_tokens',
            'content': [
              {
                'type': 'tool_use',
                'id': 'call1',
                'name': 'add_task',
                'input': {},
              },
            ],
          },
          {
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': 'Done.'},
            ],
          },
        ];
        final c = container();
        final agent = c.read(agentProvider.notifier);
        await agent.send('Add milk');
        expect(
          c.read(agentProvider).notice,
          'The reply hit its length limit and was cut short.',
        );

        await agent.send('Try again');
        expect(sentTranscripts[1], [
          {'role': 'user', 'content': 'Try again'},
        ]);
      },
    );
  });
}
