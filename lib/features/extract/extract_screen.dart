// FILE: features/extract/extract_screen.dart
// FEATURE 3 SCREEN: paste a job post, tap Extract, see the clean fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/account_button.dart';
import '../../shared/blocks.dart';
import '../../shared/model_picker.dart';
import 'extract_controller.dart';
import 'job_post.dart';

/// Feature 3 screen: paste a messy job post, get clean fields back.
class ExtractScreen extends ConsumerStatefulWidget {
  const ExtractScreen({super.key});

  @override
  ConsumerState<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends ConsumerState<ExtractScreen> {
  final _input = TextEditingController();

  static const _sample = '''We're hiring!! Mid-level Mobile Engineer @ Brightloop (Lisbon, PT or fully remote in EU timezones)
You'll own our React Native + Expo app used by 200k drivers. Must have: TypeScript, React Native, Expo, REST APIs, Git. Bonus: Flutter, Supabase, CI/CD with EAS.
Comp: EUR 55k to 70k + equity. 3+ years shipping mobile apps. Applications close 15 November 2026.''';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(extractProvider);
    final controller = ref.read(extractProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract'),
        actions: const [ModelPickerButton(), AccountButton()],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenIntro(
            title: 'Messy text in, clean fields out.',
            body: 'Paste a job post. Claude answers in a fixed JSON shape, so the app can fill a form with no guessing.',
          ),
          TextField(
            controller: _input,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: 'Paste a job post here',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: state.busy ? null : () => _input.text = _sample,
              child: const Text('Use a sample post'),
            ),
          ),
          const SizedBox(height: 8),
          state.busy
              ? OutlinedButton.icon(
                  onPressed: controller.cancel,
                  icon: const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Reading... tap to stop'),
                )
              : FilledButton(
                  onPressed: () => controller.extract(_input.text),
                  child: const Text('Extract fields'),
                ),
          if (state.notice != null) Notice(state.notice!),
          if (state.result != null) ...[
            const SizedBox(height: 20),
            _Fields(state.result!),
          ],
        ],
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields(this.job);
  final JobPost job;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Title', job.title),
      ('Company', job.company),
      ('Location', job.location),
      ('Work style', JobPost.enumLabel(job.workStyle)),
      ('Seniority', JobPost.enumLabel(job.seniority)),
      ('Salary', job.salary),
      ('Apply by', job.applyBy),
      ('Summary', job.summary),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (label, value) in rows) _Row(label: label, value: value),
        _Row(label: 'Skills', value: job.skills.join(', ')),
        _Row(label: 'Nice to have', value: job.niceToHave.join(', ')),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? JobPost.enumLabel('') : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
