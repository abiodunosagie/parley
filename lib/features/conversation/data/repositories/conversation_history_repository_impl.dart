// FILE: features/conversation/data/repositories/conversation_history_repository_impl.dart
// The real ConversationHistoryRepository, on the phone's own storage (core/storage/local_store.dart).
// Each feature has its own list: chat, look and read. The photo or PDF is saved once, as a file
// beside the conversation, instead of inside the JSON.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_store.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/repositories/conversation_history_repository.dart';
import '../mappers/conversation_json.dart';

class ConversationHistoryRepositoryImpl
    implements ConversationHistoryRepository {
  ConversationHistoryRepositoryImpl(this._store);
  final LocalStore _store;

  static const _blob = 'attachment';

  static String collectionOf(ConversationKind kind) => switch (kind) {
    ConversationKind.chat => 'chat',
    ConversationKind.vision => 'look',
    ConversationKind.document => 'read',
  };

  @override
  Future<List<SavedSummary>> list(String userId, ConversationKind kind) =>
      _store.list(userId, collectionOf(kind));

  @override
  Future<Conversation?> load(
    String userId,
    ConversationKind kind,
    String id,
  ) async {
    final collection = collectionOf(kind);
    final json = await _store.read(userId, collection, id);
    if (json == null) return null;
    try {
      final meta = json['attachment'];
      Attachment? attachment;
      if (meta is Map) {
        final bytes = await _store.readBlob(userId, collection, id, _blob);
        if (bytes == null) return null;
        attachment = Attachment(
          bytes,
          meta['media_type'] as String,
          name: meta['name'] as String?,
        );
      }
      return conversationFromJson(json, attachment: attachment);
    } catch (e) {
      debugPrint('Parley: saved conversation unreadable ($e)');
      return null;
    }
  }

  @override
  Future<void> save(String userId, Conversation conversation) async {
    final collection = collectionOf(conversation.kind);
    final file = conversation.attachment;
    if (file != null &&
        !await _store.hasBlob(userId, collection, conversation.id, _blob)) {
      await _store.writeBlob(
        userId,
        collection,
        conversation.id,
        _blob,
        file.bytes,
      );
    }
    final replies = conversation.messages.where((m) => !m.fromUser).length;
    await _store.write(
      userId,
      collection,
      SavedSummary(
        id: conversation.id,
        title: conversation.title,
        subtitle: [
          ?conversation.attachment?.name,
          '$replies ${replies == 1 ? 'reply' : 'replies'}',
          conversation.model.label,
        ].join(' · '),
        updatedAt: conversation.updatedAt,
      ),
      conversationToJson(conversation),
    );
  }

  @override
  Future<void> delete(String userId, ConversationKind kind, String id) =>
      _store.delete(userId, collectionOf(kind), id);
}

final conversationHistoryRepositoryProvider =
    Provider<ConversationHistoryRepository>(
      (ref) => ConversationHistoryRepositoryImpl(ref.watch(localStoreProvider)),
    );
