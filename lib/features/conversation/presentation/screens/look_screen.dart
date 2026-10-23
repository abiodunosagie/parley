// FILE: features/conversation/presentation/screens/look_screen.dart
// FEATURE 2 SCREEN: vision. Take or pick a photo, then ask about it. Follow-up questions keep the
// same photo, because it rides on the first message. Logic: lookControllerProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/model_picker_button.dart';
import '../../../auth/presentation/widgets/account_button.dart';
import '../../domain/repositories/photo_repository.dart';
import '../providers/conversation_controller.dart';
import '../widgets/conversation_view.dart';
import '../../../../core/widgets/intro_list.dart';
import '../widgets/pick_photo_panel.dart';
import '../widgets/photo_preview.dart';

class LookScreen extends ConsumerWidget {
  const LookScreen({super.key});

  static const _questions = [
    'What is in this photo?',
    'Read this receipt into a list of items and prices, then the total',
    'Suggest a recipe from what you can see',
    'Turn this whiteboard into clean notes',
  ];

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    PhotoSource source,
  ) async {
    final problem = await ref
        .read(lookControllerProvider.notifier)
        .pickPhoto(source);
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lookControllerProvider);
    final controller = ref.read(lookControllerProvider.notifier);
    final photo = state.photo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Look'),
        actions: [
          const ModelPickerButton(),
          if (photo != null)
            IconButton(
              tooltip: 'New photo',
              onPressed: controller.reset,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
          const AccountButton(),
        ],
      ),
      body: photo == null
          ? PickPhotoPanel(
              onCamera: () => _pick(context, ref, PhotoSource.camera),
              onLibrary: () => _pick(context, ref, PhotoSource.library),
            )
          : ConversationView(
              state: state,
              controller: controller,
              hint: state.isEmpty ? 'Ask about this photo' : 'Ask a follow-up',
              empty: IntroList(
                header: PhotoPreview(photo),
                starters: _questions,
                onPick: controller.send,
              ),
            ),
    );
  }
}
