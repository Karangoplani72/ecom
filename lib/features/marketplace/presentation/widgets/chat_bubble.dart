import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment:
      isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 320,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
          isMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              isMe ? 18 : 4,
            ),
            bottomRight: Radius.circular(
              isMe ? 4 : 18,
            ),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color:
            isMe
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );

  }
}