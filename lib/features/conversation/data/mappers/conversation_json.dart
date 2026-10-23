// FILE: features/conversation/data/mappers/conversation_json.dart
// How a Conversation is saved on the phone. The photo or PDF is not in the JSON: it is saved as
// its own file next to it (see conversation_history_repository_impl.dart).

import '../../../../core/models/claude_model.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_kind.dart';
import '../../domain/entities/source.dart';

const _version = 1;

Map<String, dynamic> conversationToJson(Conversation c) => {
  'version': _version,
  'id': c.id,
  'kind': c.kind.name,
  'model': c.model.id,
  'web_search': c.webSearch,
  'updated_at': c.updatedAt.toIso8601String(),
  'attachment': c.attachment == null
      ? null
      : {'media_type': c.attachment!.mediaType, 'name': ?c.attachment!.name},
  'messages': [
    for (final m in c.messages)
      {
        'from_user': m.fromUser,
        'text': m.text,
        if (m.thinking.isNotEmpty) 'thinking': m.thinking,
        if (m.searches.isNotEmpty) 'searches': m.searches,
        if (m.sources.isNotEmpty)
          'sources': [for (final s in m.sources) s.toJson()],
        if (m.replay.isNotEmpty) 'replay': m.replay,
      },
  ],
};

/// Rebuilds a saved conversation. [attachment] is the saved photo or PDF, read separately.
/// Throws FormatException when the JSON is not a conversation.
Conversation conversationFromJson(
  Map<String, dynamic> json, {
  Attachment? attachment,
}) {
  final kind = ConversationKind.values.asNameMap()[json['kind']];
  final model = ClaudeModel.values
      .where((m) => m.id == json['model'])
      .firstOrNull;
  final updated = DateTime.tryParse(json['updated_at'] as String? ?? '');
  final messages = json['messages'];
  if (kind == null || model == null || updated == null || messages is! List) {
    throw const FormatException('Not a saved conversation.');
  }
  final raw = messages.cast<Map<String, dynamic>>();
  // The photo or PDF belongs to the first message you sent.
  final firstUser = raw.indexWhere((m) => m['from_user'] == true);
  return Conversation(
    id: json['id'] as String,
    kind: kind,
    model: model,
    webSearch: json['web_search'] == true,
    updatedAt: updated,
    attachment: attachment,
    messages: [
      for (var i = 0; i < raw.length; i++)
        _message(raw[i], attachment: i == firstUser ? attachment : null),
    ],
  );
}

ChatMessage _message(Map<String, dynamic> m, {Attachment? attachment}) =>
    ChatMessage(
      fromUser: m['from_user'] == true,
      text: m['text'] as String? ?? '',
      attachment: attachment,
      thinking: m['thinking'] as String? ?? '',
      searches: [...(m['searches'] as List? ?? const []).whereType<String>()],
      sources: [
        for (final s in (m['sources'] as List? ?? const []).whereType<Map>())
          ?Source.fromJson(Map<String, dynamic>.from(s)),
      ],
      replay: [
        for (final b in (m['replay'] as List? ?? const []).whereType<Map>())
          Map<String, dynamic>.from(b),
      ],
    );
