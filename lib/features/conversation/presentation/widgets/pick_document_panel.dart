// FILE: features/conversation/presentation/widgets/pick_document_panel.dart
// Read's empty state: what the feature does, and a full-width button to open a PDF.

import 'package:flutter/material.dart';

import '../../../../core/widgets/notice.dart';
import '../../../../core/widgets/screen_intro.dart';

class PickDocumentPanel extends StatelessWidget {
  const PickDocumentPanel({super.key, required this.onPick, this.notice});
  final VoidCallback onPick;

  /// Why the last file could not be used, if it could not.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenIntro(
            title: 'Ask a PDF anything.',
            body: 'Contracts, manuals, papers, menus. Every answer points to the page and the exact words it came from.',
          ),
          const Spacer(),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Notice(notice!),
            ),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Open a PDF'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
