enum MessageType { text, image, location }

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String? attachmentName;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.attachmentUrl,
    this.attachmentName,
  });
}