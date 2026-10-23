// FILE: features/conversation/presentation/widgets/pick_photo_panel.dart
// Look's empty state: what the feature does, and full-width buttons for camera and library.

import 'package:flutter/material.dart';

import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';

class PickPhotoPanel extends StatelessWidget {
  const PickPhotoPanel({
    super.key,
    required this.onCamera,
    required this.onLibrary,
    this.notice,
  });
  final VoidCallback onCamera;
  final VoidCallback onLibrary;

  /// Why the last photo could not be used, if it could not.
  final String? notice;

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
          if (notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Notice(notice!),
            ),
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
