// FILE: features/conversation/presentation/providers/read_controller.dart
// Read: the shared streamed conversation (conversation_controller.dart), about a PDF. The server
// turns citations on, so every answer comes with the pages it relied on.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../domain/entities/conversation_kind.dart';
import 'conversation_controller.dart';
import 'conversation_state.dart';

class ReadController extends ConversationController {
  ReadController() : super(ConversationKind.document);

  /// Picks a PDF and starts a new conversation about it. When the file cannot be used (not a
  /// PDF, too large) the reason lands in `notice`.
  Future<void> pickDocument() async {
    try {
      final document = await ref.read(documentRepositoryProvider).pick();
      if (document == null || !ref.mounted) return;
      abandonCurrent();
      state = ConversationState(attachment: document);
    } on AppException catch (e) {
      if (ref.mounted) state = state.copyWith(notice: () => e.message);
    }
  }
}

final readControllerProvider =
    NotifierProvider<ReadController, ConversationState>(ReadController.new);
