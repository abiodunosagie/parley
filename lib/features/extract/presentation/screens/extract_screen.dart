// FILE: features/extract/presentation/screens/extract_screen.dart
// EXTRACT SCREEN: paste or dictate a job post, tap Extract, see the clean fields. History in the
// app bar.
// Logic: extractControllerProvider. This widget only owns the text box controller.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/history_sheet.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../../core/widgets/voice_button.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../providers/extract_controller.dart';
import '../providers/extract_history_provider.dart';
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
    // Opening a saved job post puts its text back in the box.
    ref.listen(extractControllerProvider, (previous, next) {
      if (next is ExtractDone && next.input != _input.text.trim()) {
        _input.text = next.input;
      }
    });

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Extract',
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => showHistorySheet(
              context,
              entries: extractHistoryProvider,
              onOpen: controller.open,
              onDelete: controller.deleteSaved,
              empty: 'Job posts you extract are kept here.',
            ),
          ),
        ],
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
            decoration: InputDecoration(
              hintText: 'Paste or dictate a job post',
              suffixIcon: VoiceButton(controller: _input),
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
