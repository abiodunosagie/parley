// FILE: core/models/saved_summary.dart
// One line in a history list: what the saved item is called, a short second line, and when it
// last changed. Plain Dart, so every feature's domain can use it.

import 'package:meta/meta.dart';

/// One line in a history list.
@immutable
class SavedSummary {
  const SavedSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'updated_at': updatedAt.toIso8601String(),
  };

  static SavedSummary? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final updated = DateTime.tryParse(json['updated_at'] as String? ?? '');
    if (id is! String || updated == null) return null;
    return SavedSummary(
      id: id,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      updatedAt: updated,
    );
  }
}

/// [text] on one line and at most [max] characters, for a history title.
String oneLineTitle(String text, {int max = 60}) {
  final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return line.length <= max ? line : '${line.substring(0, max - 3)}...';
}
