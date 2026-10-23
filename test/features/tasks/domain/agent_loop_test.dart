import 'package:flutter_test/flutter_test.dart';
import 'package:parley/core/models/claude_model.dart';
import 'package:parley/core/network/cancel_token.dart';
import 'package:parley/features/tasks/domain/entities/agent_item.dart';
import 'package:parley/features/tasks/domain/entities/agent_reply.dart';
import 'package:parley/features/tasks/domain/entities/task.dart';
import 'package:parley/features/tasks/domain/repositories/agent_repository.dart';
import 'package:parley/features/tasks/domain/services/agent_loop.dart';
import 'package:parley/features/tasks/domain/services/tool_executor.dart';

/// Plays back scripted Claude turns and records every transcript it was sent.
class _ScriptedClaude implements AgentRepository {
  _ScriptedClaude(this.replies);
  final List<AgentReply> replies;
  final sent = <List<Map<String, dynamic>>>[];

  @override
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  }) async {
    sent.add(transcript);
    return replies.removeAt(0);
  }
}

class _Phone implements ToolActions {
  final list = <Task>[];

  @override
  Future<Task> addTask({
    required String title,
    required String dueDate,
    required TaskPriority priority,
  }) async {
    final task = Task(
      id: 't${list.length + 1}',
      title: title,
      dueDate: dueDate,
      priority: priority,
    );
    list.add(task);
    return task;
  }

  @override
  Future<Task?> completeTask(String id) async => null;

  @override
  DateTime now() => DateTime(2026, 10, 23);

  @override
  Future<bool> scheduleReminder({
    required String text,
    required int minutesFromNow,
  }) async => true;

  @override
  Future<List<Task>> tasks() async => list;
}

/// Answers once from [replies], then fails like a dropped connection.
class _FailsSecond extends _ScriptedClaude {
  _FailsSecond(super.replies);

  @override
  Future<AgentReply> next({
    required ClaudeModel model,
    required List<Map<String, dynamic>> transcript,
    CancelToken? cancel,
  }) {
    if (replies.isEmpty) throw StateError('connection dropped');
    return super.next(model: model, transcript: transcript, cancel: cancel);
  }
}

/// A phone whose task list cannot be read.
class _Crashes extends _Phone {
  @override
  Future<List<Task>> tasks() async => throw StateError('storage gone');
}

/// A phone where reading the list presses Stop, as if you tapped it mid-round.
class _StopsOnRead extends _Phone {
  _StopsOnRead(this.cancel);
  final CancelToken cancel;

  @override
  Future<List<Task>> tasks() async {
    cancel.cancel();
    return list;
  }
}

AgentReply _reply(String stop, List<Map<String, dynamic>> content) =>
    AgentReply(content: content, stopReason: stop);

void main() {
  late _Phone phone;
  final items = <AgentItem>[];

  AgentLoop loop(List<AgentReply> replies) => AgentLoop(
    repository: _ScriptedClaude(replies),
    executor: ToolExecutor(phone = _Phone()),
  );

  setUp(items.clear);

  Future<AgentRunResult> run(AgentLoop l, String text) => l.run(
    text: text,
    model: ClaudeModel.opus,
    cancel: CancelToken(),
    onItem: items.add,
    isCurrent: () => true,
  );

  test('runs the tool, sends the result back in one message, keeps the finished turn', () async {
    final thinking = {'type': 'thinking', 'thinking': '', 'signature': 'sig'};
    final l = loop([
      _reply('tool_use', [
        thinking,
        {
          'type': 'tool_use',
          'id': 'call1',
          'name': 'add_task',
          'input': {'title': 'Milk', 'due_date': '', 'priority': 'low'},
        },
      ]),
      _reply('end_turn', [
        {'type': 'text', 'text': 'Added milk.'},
      ]),
    ]);
    final result = await run(l, 'Add milk');
    final claude = l.repository as _ScriptedClaude;

    expect(result.notice, isNull);
    expect(phone.list.single.title, 'Milk');
    final second = claude.sent[1];
    expect(second, hasLength(3));
    expect(
      (second[1]['content'] as List).first,
      thinking,
      reason: 'thinking goes back unchanged',
    );
    final toolResult = (second[2]['content'] as List).single as Map;
    expect(toolResult['tool_use_id'], 'call1');
    expect(toolResult.containsKey('is_error'), isFalse);
    expect(l.transcript.last, {
      'role': 'assistant',
      'content': [
        {'type': 'text', 'text': 'Added milk.'},
      ],
    });
    expect(items.whereType<ClaudeSaid>().single.text, 'Added milk.');
    expect(items.whereType<ToolRan>().single.summary, 'Added "Milk"');
  });

  test(
    'a reply cut off mid tool call is not kept, but your message is',
    () async {
      final l = loop([
        _reply('max_tokens', [
          {'type': 'tool_use', 'id': 'call1', 'name': 'add_task', 'input': {}},
        ]),
        _reply('end_turn', [
          {'type': 'text', 'text': 'Done.'},
        ]),
      ]);
      final first = await run(l, 'Add milk');
      expect(first.notice, 'The reply hit its length limit and was cut short.');
      expect(l.transcript, [
        {'role': 'user', 'content': 'Add milk'},
      ]);
      // Nothing from the cut-off reply reached the screen either.
      expect(items.whereType<ToolRan>(), isEmpty);

      await run(l, 'Try again');
      expect((l.repository as _ScriptedClaude).sent[1], [
        {'role': 'user', 'content': 'Add milk'},
        {'role': 'user', 'content': 'Try again'},
      ]);
    },
  );

  test('an empty reply is not kept', () async {
    final l = loop([_reply('end_turn', [])]);
    final result = await run(l, 'Hi');
    expect(result.notice, 'Claude did not finish. Try again.');
    expect(l.transcript, [
      {'role': 'user', 'content': 'Hi'},
    ]);
  });

  test('a run that fails after a tool ran keeps that round, as the screen shows it', () async {
    final l = AgentLoop(
      repository: _FailsSecond([
        _reply('tool_use', [
          {
            'type': 'tool_use',
            'id': 'c1',
            'name': 'add_task',
            'input': {'title': 'Milk', 'due_date': '', 'priority': 'low'},
          },
        ]),
      ]),
      executor: ToolExecutor(phone = _Phone()),
    );
    final result = await run(l, 'Add milk');
    expect(result.notice, isNotNull);
    expect(phone.list.single.title, 'Milk');
    expect(items.whereType<ToolRan>(), hasLength(1));
    // Claude will know on the next message that the task was added.
    expect(
      [for (final t in l.transcript) t['role']],
      ['user', 'assistant', 'user'],
    );
  });

  test('Stop during a tool round still answers every call', () async {
    final cancel = CancelToken();
    final l = AgentLoop(
      repository: _ScriptedClaude([
        _reply('tool_use', [
          {
            'type': 'tool_use',
            'id': 'a',
            'name': 'list_tasks',
            'input': <String, dynamic>{},
          },
          {
            'type': 'tool_use',
            'id': 'b',
            'name': 'list_tasks',
            'input': <String, dynamic>{},
          },
        ]),
      ]),
      executor: ToolExecutor(_StopsOnRead(cancel)),
    );
    final result = await l.run(
      text: 'Read twice',
      model: ClaudeModel.opus,
      cancel: cancel,
      onItem: items.add,
      isCurrent: () => true,
    );
    expect(result.notice, 'Stopped.');
    final results = l.transcript.last['content'] as List;
    expect([for (final r in results) r['tool_use_id']], ['a', 'b']);
    expect((results[1] as Map)['is_error'], isTrue);
  });

  test(
    'a tool that crashes is answered as an error and still logged',
    () async {
      final l = AgentLoop(
        repository: _ScriptedClaude([
          _reply('tool_use', [
            {
              'type': 'tool_use',
              'id': 'x',
              'name': 'list_tasks',
              'input': <String, dynamic>{},
            },
          ]),
          _reply('end_turn', [
            {'type': 'text', 'text': 'Sorry, that failed.'},
          ]),
        ]),
        executor: ToolExecutor(_Crashes()),
      );
      final result = await run(l, 'What is on my list?');
      expect(result.unexpectedError, isA<StateError>());
      final results = l.transcript[2]['content'] as List;
      expect((results.single as Map)['is_error'], isTrue);
      expect(l.transcript.last['role'], 'assistant');
    },
  );

  test('a tool_use stop with no calls ends as a plain answer, never an empty round', () async {
    final l = loop([
      _reply('tool_use', [
        {'type': 'text', 'text': 'Let me check.'},
      ]),
    ]);
    await run(l, 'Hi');
    expect([for (final t in l.transcript) t['role']], ['user', 'assistant']);
    expect(items.whereType<ClaudeSaid>().single.text, 'Let me check.');
  });

  test('stops after the round limit', () async {
    final call = {
      'type': 'tool_use',
      'id': 'c',
      'name': 'list_tasks',
      'input': <String, dynamic>{},
    };
    final l = AgentLoop(
      repository: _ScriptedClaude([
        for (var i = 0; i < 3; i++) _reply('tool_use', [call]),
      ]),
      executor: ToolExecutor(phone = _Phone()),
      maxRounds: 3,
    );
    final result = await run(l, 'Loop forever');
    expect(result.notice, 'Claude used too many steps. Try a simpler request.');
    // Every round that ran is complete, so the conversation can carry on.
    expect(l.transcript.last['role'], 'user');
  });
}
