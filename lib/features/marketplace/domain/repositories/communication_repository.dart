import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_room.dart';

abstract class CommunicationRepository {
  // ── Messages ────────────────────────────────────────────────────────────────
  Stream<List<ChatMessage>> streamRoomMessages(String roomId, {int limit});
  Future<Either<String, Unit>> dispatchLiveMessage(
      String roomId, ChatMessage message);

  // ── Chat Rooms ───────────────────────────────────────────────────────────────
  /// Streams all chat rooms where [userId] is a participant, ordered by
  /// most-recent message first.
  Stream<List<ChatRoom>> streamChatRooms(String userId, {bool isStaff = false});

  /// Creates a chat room for [buyerId] ↔ [sellerId] if it doesn't exist,
  /// or returns the existing one.  Returns the chatId on success.
  Future<Either<String, String>> createOrGetChatRoom({
    required String buyerId,
    required String sellerId,
    required String buyerName,
    required String sellerName,
    String? buyerPhotoUrl,
    String? sellerPhotoUrl,
  });

  /// Resets the unread counter for [userId] in [chatId] to 0.
  Future<void> markRoomRead(String chatId, String userId);

  /// Sets the typing indicator field for [userId] in [chatId].
  Future<void> setTyping(String chatId, String userId, bool isTyping);

  /// Streams the typing status of the OTHER party from [userId]'s perspective.
  Stream<bool> streamOtherTyping(String chatId, String userId);

  // ── Device Tokens ────────────────────────────────────────────────────────────
  Future<Either<String, Unit>> registerDevicePushToken(
      String userId, String token);
}