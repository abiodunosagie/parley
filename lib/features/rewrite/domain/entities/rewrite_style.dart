// FILE: features/rewrite/domain/entities/rewrite_style.dart
// The ways Parley can rewrite your text, and the instruction each one sends to Claude.

enum RewriteStyle {
  shorter('Shorter', 'Make this shorter and clearer. Keep every key point.'),
  formal('Formal', 'Make this more formal and professional.'),
  friendly('Friendly', 'Make this warmer and more friendly.'),
  fix(
    'Fix grammar',
    'Fix spelling, grammar and punctuation. Change nothing else.',
  ),
  translate('Translate', 'Translate this into {language}.');

  const RewriteStyle(this.label, this._instruction);
  final String label;
  final String _instruction;

  /// The instruction for Claude. [language] only matters for [translate].
  String instruction({String language = 'English'}) =>
      _instruction.replaceAll('{language}', language);

  static RewriteStyle parse(Object? value) =>
      values.asNameMap()[value] ?? RewriteStyle.shorter;
}

/// Languages offered for [RewriteStyle.translate].
const rewriteLanguages = [
  'English',
  'French',
  'Spanish',
  'Portuguese',
  'German',
  'Italian',
  'Yoruba',
];
