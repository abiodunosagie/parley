// FILE: features/conversation/presentation/providers/look_controller.dart
// Look: the shared streamed conversation (conversation_controller.dart), plus the photo it is
// about.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/repositories/photo_repository.dart';
import 'conversation_controller.dart';
import 'conversation_state.dart';

class LookController extends ConversationController {
  LookController() : super(ConversationKind.vision);

  /// Takes or picks a photo and starts a new conversation about it. When the photo cannot be
  /// used (access denied, unsupported file) the reason lands in `notice`.
  Future<void> pickPhoto(PhotoSource source) async {
    try {
      final photo = await ref.read(photoRepositoryProvider).pick(source);
      if (photo == null || !ref.mounted) return;
      abandonCurrent();
      state = ConversationState(attachment: photo);
    } on AppException catch (e) {
      if (ref.mounted) state = state.copyWith(notice: () => e.message);
    }
  }
}

final lookControllerProvider =
    NotifierProvider<LookController, ConversationState>(LookController.new);
