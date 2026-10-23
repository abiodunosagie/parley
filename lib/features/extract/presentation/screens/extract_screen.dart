// FILE: features/extract/presentation/screens/extract_screen.dart
// FEATURE 3 SCREEN: paste a job post, tap Extract, see the clean fields.
// Logic: extractControllerProvider. This widget only owns the text box controller.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/model_picker_button.dart';
import '../../../../core/widgets/notice_line.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../auth/presentation/widgets/account_button.dart';
import '../providers/extract_controller.dart';
import '../widgets/extract_button.dart';
import '../widgets/job_post_fields.dart';

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
    final state = ref.watch(extractControllerProvider);
    final controller = ref.read(extractControllerProvider.notifier);
    final busy = state is Extracting;

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
              onPressed: busy ? null : () => _input.text = _sample,
              child: const Text('Use a sample post'),
            ),
          ),
          const SizedBox(height: 8),
          ExtractButton(
            busy: busy,
            onExtract: () => controller.extract(_input.text),
            onStop: controller.cancel,
          ),
          ...switch (state) {
            ExtractFailed(:final message) => [Notice(message)],
            ExtractDone(:final job) => [
              const SizedBox(height: 20),
              JobPostFields(job),
            ],
            ExtractIdle() || Extracting() => const <Widget>[],
          },
        ],
      ),
    );
  }
}
