// FILE: features/conversation/presentation/widgets/pick_photo_panel.dart
// Look's empty state: what the feature does, and full-width buttons for camera and library.

import 'package:flutter/material.dart';

import '../../../../core/widgets/screen_intro.dart';

class PickPhotoPanel extends StatelessWidget {
  const PickPhotoPanel({
    super.key,
    required this.onCamera,
    required this.onLibrary,
  });
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
