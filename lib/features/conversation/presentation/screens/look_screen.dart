// FILE: features/conversation/presentation/screens/look_screen.dart
// FEATURE 2 SCREEN: vision. Take or pick a photo, then ask about it. Follow-up questions keep the
// same photo, because it rides on the first message. Logic: lookControllerProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/feature_app_bar.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lookControllerProvider);
    final controller = ref.read(lookControllerProvider.notifier);
    final photo = state.photo;

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Look',
        actions: [
          if (photo != null)
            IconButton(
              tooltip: 'New photo',
              onPressed: controller.reset,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
        ],
      ),
      body: photo == null
          ? PickPhotoPanel(
              notice: state.notice,
              onCamera: () => controller.pickPhoto(PhotoSource.camera),
              onLibrary: () => controller.pickPhoto(PhotoSource.library),
            )
          : ConversationView(
              state: state,
              onSend: controller.send,
              onStop: controller.stop,
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
