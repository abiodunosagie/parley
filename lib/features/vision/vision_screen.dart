// FILE: features/vision/vision_screen.dart
// FEATURE 2 SCREEN: vision. Take or pick a photo, then ask about it. The photo is
// resized to 1568 px and sent as a base64 image block with your first question.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../shared/account_button.dart';
import '../../shared/blocks.dart';
import '../../shared/composer.dart';
import '../../shared/model_picker.dart';
import '../conversation/attachment.dart';
import '../conversation/conversation.dart';
import '../conversation/message_list.dart';

/// Feature 2: vision. Take or pick a photo, then ask Claude about it. Follow-up questions keep
/// the same photo, because it rides on the first message of the conversation.
class VisionScreen extends ConsumerWidget {
  const VisionScreen({super.key});

  static const _questions = [
    'What is in this photo?',
    'Read this receipt into a list of items and prices, then the total',
    'Suggest a recipe from what you can see',
    'Turn this whiteboard into clean notes',
  ];

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    void tell(String message) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final XFile? file;
    try {
      // 1568 px on the long edge is the largest size Claude uses without downscaling it again.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1568,
        maxHeight: 1568,
        imageQuality: 85,
      );
    } on PlatformException {
      tell('Parley needs camera or photo access. Turn it on in Settings.');
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final type = Attachment.mediaTypeOf(bytes);
    if (type == null) {
      tell(
        'That file type is not supported. Use a JPEG, PNG, WebP or GIF image.',
      );
      return;
    }
    ref.read(visionProvider.notifier).attachPhoto(Attachment(bytes, type));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visionProvider);
    final vision = ref.read(visionProvider.notifier);
    final photo = state.photo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Look'),
        actions: [
          const ModelPickerButton(),
          if (photo != null)
            IconButton(
              tooltip: 'New photo',
              onPressed: vision.reset,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
          const AccountButton(),
        ],
      ),
      body: photo == null
          ? _PickPhoto(
              onCamera: () => _pick(context, ref, ImageSource.camera),
              onLibrary: () => _pick(context, ref, ImageSource.gallery),
            )
          : Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(16),
                          children: [
                            ClipRRect(
                              borderRadius: kRadius,
                              child: Image.memory(
                                photo.bytes,
                                height: 260,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StarterButtons(
                              items: _questions,
                              onPick: vision.send,
                            ),
                          ],
                        )
                      : MessageList(messages: state.messages, busy: state.busy),
                ),
                if (state.notice != null) Notice(state.notice!),
                Composer(
                  busy: state.busy,
                  onSend: vision.send,
                  onStop: vision.stop,
                  hint: state.messages.isEmpty
                      ? 'Ask about this photo'
                      : 'Ask a follow-up',
                ),
              ],
            ),
    );
  }
}

class _PickPhoto extends StatelessWidget {
  const _PickPhoto({required this.onCamera, required this.onLibrary});
  final VoidCallback onCamera;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenIntro(
            title: 'Show Claude a photo.',
            body: 'Receipts, menus, whiteboards, a fridge shelf. Claude reads what is really there.',
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Take a photo'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onLibrary,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from library'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
