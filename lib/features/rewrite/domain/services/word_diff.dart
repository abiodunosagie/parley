// FILE: features/rewrite/domain/services/word_diff.dart
// Which words a rewrite kept, removed and added, so the screen can highlight the changes.
// A word-level longest-common-subsequence diff. Plain Dart, covered by
// test/features/rewrite/domain/word_diff_test.dart.

import 'package:meta/meta.dart';

enum DiffOp { same, removed, added }

@immutable
class DiffPart {
  const DiffPart(this.op, this.text);
  final DiffOp op;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DiffPart && other.op == op && other.text == text;

  @override
  int get hashCode => Object.hash(op, text);

  @override
  String toString() => '${op.name}("$text")';
}

/// Words with the spaces after them, so joining the parts gives the text back exactly.
List<String> _tokens(String text) =>
    RegExp(r'\S+\s*|\s+').allMatches(text).map((m) => m.group(0)!).toList();

/// Above this many word pairs the table gets too big for a phone, so the whole text counts as
/// replaced instead.
const _maxCells = 250000;

/// The parts of [after] compared with [before], in reading order. Neighbouring parts with the
/// same op are merged.
List<DiffPart> wordDiff(String before, String after) {
  final a = _tokens(before);
  final b = _tokens(after);
  if (a.length * b.length > _maxCells) {
    return _merge([
      if (before.isNotEmpty) DiffPart(DiffOp.removed, before),
      if (after.isNotEmpty) DiffPart(DiffOp.added, after),
    ]);
  }
  // Words compare without their trailing spaces, so a moved line break is not a change.
  String word(String t) => t.trimRight();

  // lcs[i][j] = length of the common subsequence of a[i..] and b[j..].
  final lcs = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      lcs[i][j] = word(a[i]) == word(b[j])
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final parts = <DiffPart>[];
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    if (word(a[i]) == word(b[j])) {
      parts.add(DiffPart(DiffOp.same, b[j]));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      parts.add(DiffPart(DiffOp.removed, a[i++]));
    } else {
      parts.add(DiffPart(DiffOp.added, b[j++]));
    }
  }
  while (i < a.length) {
    parts.add(DiffPart(DiffOp.removed, a[i++]));
  }
  while (j < b.length) {
    parts.add(DiffPart(DiffOp.added, b[j++]));
  }
  return _merge(parts);
}

List<DiffPart> _merge(List<DiffPart> parts) {
  final merged = <DiffPart>[];
  for (final part in parts) {
    if (merged.isNotEmpty && merged.last.op == part.op) {
      merged[merged.length - 1] = DiffPart(
        part.op,
        merged.last.text + part.text,
      );
    } else {
      merged.add(part);
    }
  }
  return merged;
}
