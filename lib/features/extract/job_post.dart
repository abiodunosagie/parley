// FILE: features/extract/job_post.dart
// The fields Claude fills in from a pasted job post. The server forces Claude's
// answer to match this exact shape (structured output), so parsing it can never fail on a typo.

import 'package:flutter/foundation.dart';

/// The fields Claude fills from a pasted job post. The shape is fixed by `JOB_POST_SCHEMA` in
/// `supabase/functions/claude/schemas.ts`; structured output guarantees the reply matches it.
@immutable
class JobPost {
  const JobPost({
    required this.title,
    required this.company,
    required this.location,
    required this.workStyle,
    required this.seniority,
    required this.salary,
    required this.skills,
    required this.niceToHave,
    required this.summary,
    required this.applyBy,
  });

  final String title;
  final String company;
  final String location;

  /// remote, hybrid, onsite or not_stated (the schema's `remote` field).
  final String workStyle;
  final String seniority;
  final String salary;
  final List<String> skills;
  final List<String> niceToHave;
  final String summary;
  final String applyBy;

  factory JobPost.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] as String?)?.trim() ?? '';
    List<String> list(String key) => [
      for (final v in (json[key] as List?) ?? const [])
        if (v is String && v.trim().isNotEmpty) v.trim(),
    ];
    return JobPost(
      title: text('title'),
      company: text('company'),
      location: text('location'),
      workStyle: text('remote'),
      seniority: text('seniority'),
      salary: text('salary'),
      skills: list('skills'),
      niceToHave: list('nice_to_have'),
      summary: text('summary'),
      applyBy: text('apply_by'),
    );
  }

  /// A schema enum value as words: "not_stated" reads "Not stated", "onsite" reads "On site".
  static String enumLabel(String value) => switch (value) {
    'not_stated' || '' => 'Not stated',
    'onsite' => 'On site',
    _ => value[0].toUpperCase() + value.substring(1),
  };
}
