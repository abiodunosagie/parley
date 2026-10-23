// FILE: features/rewrite/presentation/screens/rewrite_screen.dart
// REWRITE SCREEN: paste or dictate text, pick a style, and the rewrite streams in. Turn on
// "Show changes" to see exactly what Claude changed. History in the app bar.
// Logic: rewriteControllerProvider. This widget only owns the text box controller.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/widgets/history_sheet.dart';
import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';
import '../../../../core/widgets/voice_button.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../providers/rewrite_controller.dart';
import '../providers/rewrite_history_provider.dart';
import '../widgets/rewrite_result.dart';
import '../widgets/style_picker.dart';

class RewriteScreen extends ConsumerStatefulWidget {
  const RewriteScreen({super.key});

  @override
  ConsumerState<RewriteScreen> createState() => _RewriteScreenState();
}

class _RewriteScreenState extends ConsumerState<RewriteScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewriteControllerProvider);
    final controller = ref.read(rewriteControllerProvider.notifier);
    // Opening a saved rewrite puts its text back in the box.
    ref.listen(rewriteControllerProvider.select((s) => s.id), (previous, next) {
      final opened = ref.read(rewriteControllerProvider);
      if (next != null && opened.input != _input.text.trim()) {
        _input.text = opened.input;
      }
    });

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Rewrite',
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => showHistorySheet(
              context,
              entries: rewriteHistoryProvider,
              onOpen: controller.open,
              onDelete: controller.deleteSaved,
              empty: 'Finished rewrites are kept here.',
            ),
          ),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenIntro(
            title: 'Say it better.',
            body: 'Shorter, more formal, friendlier, fixed, or in another language. The rewrite streams in, and you can see every change.',
          ),
          TextField(
            controller: _input,
            minLines: 5,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: 'Paste or dictate your text',
              suffixIcon: VoiceButton(controller: _input),
            ),
          ),
          const SizedBox(height: 16),
          StylePicker(
            style: state.style,
            language: state.language,
            enabled: !state.writing,
            onStyle: controller.setStyle,
            onLanguage: controller.setLanguage,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: kButtonHeight,
            child: state.writing
                ? OutlinedButton(
                    onPressed: controller.stop,
                    child: const Text('Stop'),
                  )
                : FilledButton(
                    onPressed: () => controller.run(_input.text),
                    child: const Text('Rewrite'),
                  ),
          ),
          if (state.notice != null) Notice(state.notice!),
          if (state.output.isNotEmpty) ...[
            const SizedBox(height: 20),
            RewriteResult(
              before: state.input,
              after: state.output,
              finished: state.status == RewriteStatus.done,
            ),
          ],
        ],
      ),
    );
  }
}
