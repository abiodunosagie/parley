// FILE: features/rewrite/domain/entities/rewrite.dart
// One finished rewrite, as saved in history: what you wrote, how it was rewritten, and the result.

import 'package:meta/meta.dart';

import 'rewrite_style.dart';

@immutable
class Rewrite {
  const Rewrite({
    required this.id,
    required this.input,
    required this.style,
    required this.language,
    required this.output,
    required this.createdAt,
  });

  final String id;
  final String input;
  final RewriteStyle style;

  /// The target language when [style] is translate.
  final String language;
  final String output;
  final DateTime createdAt;

  /// "Shorter", or "Translate to French".
  String get label =>
      style == RewriteStyle.translate ? 'Translate to $language' : style.label;

  factory Rewrite.fromJson(Map<String, dynamic> json) => Rewrite(
    id: json['id'] as String,
    input: json['input'] as String,
    style: RewriteStyle.parse(json['style']),
    language: json['language'] as String? ?? 'English',
    output: json['output'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'input': input,
    'style': style.name,
    'language': language,
    'output': output,
    'created_at': createdAt.toIso8601String(),
  };
}
