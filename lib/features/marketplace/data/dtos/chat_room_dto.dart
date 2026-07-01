import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_room.dart';

class ChatRoomDto {
  final String chatId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String? buyerPhotoUrl;
  final String? sellerPhotoUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int buyerUnread;
  final int sellerUnread;

  ChatRoomDto({
    required this.chatId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    this.buyerPhotoUrl,
    this.sellerPhotoUrl,
    required this.lastMessage,
    this.lastMessageAt,
    required this.buyerUnread,
    required this.sellerUnread,
  });

  factory ChatRoomDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final lastMsgAt = data['lastMessageAt'];
    return ChatRoomDto(
      chatId: doc.id,
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? 'Buyer',
      sellerName: data['sellerName'] as String? ?? 'Seller',
      buyerPhotoUrl: data['buyerPhotoUrl'] as String?,
      sellerPhotoUrl: data['sellerPhotoUrl'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt:
          lastMsgAt is Timestamp ? lastMsgAt.toDate() : null,
      buyerUnread: (data['buyerUnread'] as num?)?.toInt() ?? 0,
      sellerUnread: (data['sellerUnread'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'buyerName': buyerName,
        'sellerName': sellerName,
        if (buyerPhotoUrl != null) 'buyerPhotoUrl': buyerPhotoUrl,
        if (sellerPhotoUrl != null) 'sellerPhotoUrl': sellerPhotoUrl,
        'lastMessage': lastMessage,
        'participants': [buyerId, sellerId],
        'lastMessageAt': lastMessageAt != null
            ? Timestamp.fromDate(lastMessageAt!)
            : null,
        'buyerUnread': buyerUnread,
        'sellerUnread': sellerUnread,
      };

  ChatRoom toDomain() => ChatRoom(
        chatId: chatId,
        buyerId: buyerId,
        sellerId: sellerId,
        buyerName: buyerName,
        sellerName: sellerName,
        buyerPhotoUrl: buyerPhotoUrl,
        sellerPhotoUrl: sellerPhotoUrl,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        buyerUnread: buyerUnread,
        sellerUnread: sellerUnread,
      );
}
