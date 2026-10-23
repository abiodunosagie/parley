// FILE: features/conversation/presentation/screens/read_screen.dart
// FEATURE 3 SCREEN: documents with citations. Open a PDF, ask about it, and every answer lists the
// pages and quotes it relied on. History in the app bar. Logic: readControllerProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/intro_list.dart';
import '../../../home/presentation/widgets/feature_app_bar.dart';
import '../../domain/entities/conversation_kind.dart';
import '../providers/read_controller.dart';
import '../widgets/conversation_view.dart';
import '../widgets/document_header.dart';
import '../widgets/history_button.dart';
import '../widgets/pick_document_panel.dart';

class ReadScreen extends ConsumerWidget {
  const ReadScreen({super.key});

  static const _questions = [
    'Summarise this document in five bullet points',
    'What are the key dates and deadlines?',
    'What does this say about costs or payment?',
    'List anything I should be careful about',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readControllerProvider);
    final controller = ref.read(readControllerProvider.notifier);
    final document = state.attachment;

    return Scaffold(
      appBar: FeatureAppBar(
        title: 'Read',
        actions: [
          ConversationHistoryButton(
            kind: ConversationKind.document,
            controller: controller,
          ),
          if (document != null)
            IconButton(
              tooltip: 'New document',
              onPressed: controller.reset,
              icon: const Icon(Icons.note_add_outlined),
            ),
        ],
      ),
      body: document == null
          ? PickDocumentPanel(
              notice: state.notice,
              onPick: controller.pickDocument,
            )
          : ConversationView(
              state: state,
              onSend: controller.send,
              onStop: controller.stop,
              hint: state.isEmpty
                  ? 'Ask about this document'
                  : 'Ask a follow-up',
              empty: IntroList(
                header: DocumentHeader(document),
                starters: _questions,
                onPick: controller.send,
              ),
            ),
    );
  }
}
