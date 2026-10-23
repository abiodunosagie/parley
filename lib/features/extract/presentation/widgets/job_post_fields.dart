// FILE: features/extract/presentation/widgets/job_post_fields.dart
// The extracted job post as a list of labelled fields.

import 'package:flutter/material.dart';

import '../../domain/entities/job_post.dart';
import 'field_row.dart';

class JobPostFields extends StatelessWidget {
  const JobPostFields(this.job, {super.key});
  final JobPost job;

  /// A schema enum value as words: "not_stated" reads empty (shown as "Not stated"), "onsite"
  /// reads "On site", anything else is capitalised.
  static String enumLabel(String value) => switch (value) {
    'not_stated' || '' => '',
    'onsite' => 'On site',
    _ => value[0].toUpperCase() + value.substring(1),
  };

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Title', job.title),
      ('Company', job.company),
      ('Location', job.location),
      ('Work style', enumLabel(job.workStyle)),
      ('Seniority', enumLabel(job.seniority)),
      ('Salary', job.salary),
      ('Apply by', job.applyBy),
      ('Summary', job.summary),
      ('Skills', job.skills.join(', ')),
      ('Nice to have', job.niceToHave.join(', ')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in rows) FieldRow(label: label, value: value),
      ],
    );
  }
}
