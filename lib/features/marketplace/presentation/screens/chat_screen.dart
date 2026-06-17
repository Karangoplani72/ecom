import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/chat_bubble.dart';



class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
  TextEditingController();

  final String currentUserId = 'buyer_001';

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();

  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              colorScheme.primaryContainer,
              child: Icon(
                Icons.storefront,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Support Chat',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'Online',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy(
                'createdAt',
                descending: false,
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 72,
                          color: colorScheme
                              .primary,
                        ),
                        const SizedBox(
                            height: 16),
                        Text(
                          'No messages yet',
                          style: theme
                              .textTheme
                              .titleMedium,
                        ),
                        const SizedBox(
                            height: 8),
                        Text(
                          'Start the conversation',
                          style: theme
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder:
                      (context, index) {
                    final data =
                    docs[index].data()
                    as Map<String,
                        dynamic>;

                    return ChatBubble(
                      message:
                      data['text'] ?? '',
                      isMe:
                      data['senderId'] ==
                          currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme
                        .outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _messageController,
                      textCapitalization:
                      TextCapitalization
                          .sentences,
                      minLines: 1,
                      maxLines: 5,
                      decoration:
                      InputDecoration(
                        hintText:
                        'Type a message...',
                        prefixIcon:
                        const Icon(
                          Icons.chat,
                        ),
                      ),
                      onSubmitted: (_) =>
                          _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed:
                    _sendMessage,
                    style:
                    FilledButton.styleFrom(
                      shape:
                      const CircleBorder(),
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
}