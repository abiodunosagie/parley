import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/rewrite/domain/services/word_diff.dart';

String rebuild(List<DiffPart> parts, {required bool after}) => [
  for (final p in parts)
    if (p.op == DiffOp.same || p.op == (after ? DiffOp.added : DiffOp.removed))
      p.text,
].join();

void main() {
  test('unchanged text is one same part', () {
    expect(wordDiff('hello there', 'hello there'), [
      const DiffPart(DiffOp.same, 'hello there'),
    ]);
  });

  test('a replaced word shows as removed then added', () {
    expect(wordDiff('meeting moved to 3', 'meeting moved to 4'), const [
      DiffPart(DiffOp.same, 'meeting moved to '),
      DiffPart(DiffOp.removed, '3'),
      DiffPart(DiffOp.added, '4'),
    ]);
  });

  test('the parts always rebuild both texts exactly', () {
    const before = 'hey guys, meeting moved to 3, dont be late';
    const after =
        'Hello all, the meeting has moved to 3 PM. Please do not be late.';
    final parts = wordDiff(before, after);
    expect(rebuild(parts, after: true), after);
    expect(rebuild(parts, after: false), before);
  });

  test('empty texts', () {
    expect(wordDiff('', 'new text'), [
      const DiffPart(DiffOp.added, 'new text'),
    ]);
    expect(wordDiff('old', ''), [const DiffPart(DiffOp.removed, 'old')]);
    expect(wordDiff('', ''), isEmpty);
  });

  test(
    'very long texts fall back to a whole replacement instead of a huge table',
    () {
      final before = List.filled(600, 'a').join(' ');
      final after = List.filled(600, 'b').join(' ');
      final parts = wordDiff(before, after);
      expect([for (final p in parts) p.op], [DiffOp.removed, DiffOp.added]);
      expect(rebuild(parts, after: true), after);
    },
  );
}
