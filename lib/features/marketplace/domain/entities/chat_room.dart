/// Represents a chat thread between a buyer and a seller.
class ChatRoom {
  /// Deterministic ID: sorted(buyerId, sellerId) joined with '_'
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

  const ChatRoom({
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

  /// Returns the unread count for [userId].
  int unreadFor(String userId) {
    if (userId == buyerId) return buyerUnread;
    if (userId == sellerId) return sellerUnread;
    return 0;
  }

  /// Returns the display name of the OTHER party (from [userId]'s perspective).
  String otherName(String userId) =>
      userId == buyerId ? sellerName : buyerName;

  /// Returns the photo URL of the OTHER party.
  String? otherPhotoUrl(String userId) =>
      userId == buyerId ? sellerPhotoUrl : buyerPhotoUrl;
}
