// FILE: features/conversation/presentation/widgets/user_turn.dart
// One message you sent, in the shared UserBubble, with the photo (Look) or the PDF's name (Read)
// above the text.

import 'package:flutter/material.dart';

import '../../../../core/widgets/user_bubble.dart';
import '../../domain/entities/chat_message.dart';

/// One of your messages, with its photo when it has one.
class UserTurn extends StatelessWidget {
  const UserTurn(this.message, {super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final file = message.attachment;
    return UserBubble(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (file != null && file.isPdf)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      file.name ?? 'Document',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else if (file != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(file.bytes, height: 140, fit: BoxFit.cover),
              ),
            ),
          Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
