import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/tasks/domain/entities/agent_item.dart';
import 'package:parley/features/tasks/domain/entities/agent_reply.dart';

void main() {
  test('every line of a Tasks conversation survives a save and load', () {
    const items = <AgentItem>[
      UserSaid('Add milk'),
      ClaudeThought('Check the list first.'),
      ToolRan('add_task Milk', isError: false),
      ClaudeSaid('Added.'),
    ];
    final again = [for (final i in items) AgentItem.fromJson(i.toJson())];
    expect(
      [for (final i in again) i.runtimeType],
      [UserSaid, ClaudeThought, ToolRan, ClaudeSaid],
    );
    expect((again[2] as ToolRan).isError, isFalse);
  });

  test('unknown saved lines are skipped, not crashed on', () {
    expect(AgentItem.fromJson({'kind': 'video', 'text': 'x'}), isNull);
    expect(AgentItem.fromJson({'kind': 'user'}), isNull);
  });

  test("a reply's reasoning comes from its thinking blocks", () {
    const reply = AgentReply(
      content: [
        {'type': 'thinking', 'thinking': ' Plan it. ', 'signature': 's'},
        {'type': 'thinking', 'thinking': '', 'signature': 's'},
        {'type': 'text', 'text': 'Done'},
      ],
      stopReason: 'end_turn',
    );
    expect(reply.thoughts.toList(), ['Plan it.']);
  });
}
