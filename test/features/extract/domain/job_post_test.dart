import 'package:flutter_test/flutter_test.dart';
import 'package:parley/features/extract/domain/entities/job_post.dart';
import 'package:parley/features/extract/presentation/widgets/job_post_fields.dart';

void main() {
  group('JobPost.fromJson', () {
    test('trims values and drops empty list items', () {
      final job = JobPost.fromJson({
        'title': ' Mobile Engineer ',
        'company': 'Brightloop',
        'location': '',
        'remote': 'hybrid',
        'seniority': 'mid',
        'salary': 'EUR 55k to 70k',
        'skills': ['TypeScript', ' ', 'Expo'],
        'nice_to_have': [],
        'summary': 'Own the app.',
        'apply_by': '',
      });
      expect(job.title, 'Mobile Engineer');
      expect(job.skills, ['TypeScript', 'Expo']);
      expect(JobPostFields.enumLabel(job.workStyle), 'Hybrid');
      expect(JobPostFields.enumLabel('not_stated'), '');
      expect(JobPostFields.enumLabel('onsite'), 'On site');
    });

    test('missing keys become empty values instead of crashing', () {
      final job = JobPost.fromJson({});
      expect(job.title, '');
      expect(job.skills, isEmpty);
    });
  });
}
