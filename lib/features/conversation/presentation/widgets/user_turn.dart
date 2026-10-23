// FILE: features/conversation/presentation/widgets/user_turn.dart
// One message you sent, in the shared UserBubble, with the photo above the text in Look.

import 'package:flutter/material.dart';

import '../../../../core/widgets/user_bubble.dart';
import '../../domain/entities/chat_message.dart';

/// One of your messages, with its photo when it has one.
class UserTurn extends StatelessWidget {
  const UserTurn(this.message, {super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final photo = message.attachment;
    return UserBubble(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (photo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  photo.bytes,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
