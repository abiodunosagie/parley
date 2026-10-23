// FILE: features/conversation/data/repositories/conversation_history_repository_impl.dart
// The real ConversationHistoryRepository, on the phone's own storage
// (core/storage/saved_collection.dart). Each feature has its own list: chat, look and read. The
// photo or PDF is saved once, as a file beside the conversation, instead of inside the JSON.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_store.dart';
import '../../../../core/storage/saved_collection.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/repositories/conversation_history_repository.dart';
import '../mappers/conversation_json.dart';

class ConversationHistoryRepositoryImpl
    implements ConversationHistoryRepository {
  ConversationHistoryRepositoryImpl(LocalStore store)
    : _collections = {
        for (final kind in ConversationKind.values)
          kind: SavedCollection(store, switch (kind) {
            ConversationKind.chat => 'chat',
            ConversationKind.vision => 'look',
            ConversationKind.document => 'read',
          }),
      };

  final Map<ConversationKind, SavedCollection> _collections;

  static const _file = 'attachment';

  @override
  Future<List<SavedSummary>> history(String userId, ConversationKind kind) =>
      _collections[kind]!.history(userId);

  @override
  Future<Conversation?> load(String userId, ConversationKind kind, String id) {
    final collection = _collections[kind]!;
    return collection.load(userId, id, (json) async {
      final meta = json['attachment'];
      if (meta is! Map) return conversationFromJson(json);
      final bytes = await collection.file(userId, id, _file);
      if (bytes == null) return null;
      return conversationFromJson(
        json,
        attachment: Attachment(
          bytes,
          meta['media_type'] as String,
          name: meta['name'] as String?,
        ),
      );
    });
  }

  @override
  Future<void> save(String userId, Conversation conversation) {
    final file = conversation.attachment;
    final replies = conversation.messages.where((m) => !m.fromUser).length;
    return _collections[conversation.kind]!.save(
      userId,
      SavedSummary(
        id: conversation.id,
        title: conversation.title,
        subtitle: [
          ?file?.name,
          '$replies ${replies == 1 ? 'reply' : 'replies'}',
          conversation.model.label,
        ].join(' · '),
        updatedAt: conversation.updatedAt,
      ),
      conversationToJson(conversation),
      file: file == null ? null : (name: _file, bytes: file.bytes),
    );
  }

  @override
  Future<void> delete(String userId, ConversationKind kind, String id) =>
      _collections[kind]!.delete(userId, id);
}

final conversationHistoryRepositoryProvider =
    Provider<ConversationHistoryRepository>(
      (ref) => ConversationHistoryRepositoryImpl(ref.watch(localStoreProvider)),
    );
