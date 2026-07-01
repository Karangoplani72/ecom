import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/repositories/communication_repository.dart';
import 'package:ecom/features/marketplace/data/dtos/chat_message_dto.dart';
import 'package:ecom/features/marketplace/data/dtos/chat_room_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_room.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final FirebaseFirestore _firestore;

  CommunicationRepositoryImpl({required this._firestore});

  // ── Deterministic chat room ID ─────────────────────────────────────────────
  static String _roomId(String buyerId, String sellerId) {
    final ids = [buyerId, sellerId]..sort();
    return ids.join('_');
  }

  // ── Messages ────────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> streamRoomMessages(String roomId,
      {int limit = 100}) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessageDto.fromFirestore(doc).toDomain())
            .toList());
  }

  @override
  Future<Either<String, Unit>> dispatchLiveMessage(
      String roomId, ChatMessage message) async {
    try {
      final batch = _firestore.batch();

      final msgRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc();

      final msgMap = {
        'senderId': message.senderId,
        'text': message.text,
        'type': message.type.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        if (message.attachmentUrl != null)
          'attachmentUrl': message.attachmentUrl,
        // roomId is stored for consistency with the DTO
        'roomId': roomId,
      };
      batch.set(msgRef, msgMap);

      // Determine who is buyer and who is seller from the room doc to increment
      // the correct unread counter.
      final roomRef = _firestore.collection('chats').doc(roomId);
      final roomSnap = await roomRef.get();
      final data = roomSnap.data() ?? {};
      final buyerId = data['buyerId'] as String? ?? '';
      final isSender = message.senderId == buyerId;
      final unreadField = isSender ? 'sellerUnread' : 'buyerUnread';

      batch.set(
        roomRef,
        {
          'lastMessage': message.text.isNotEmpty
              ? message.text
              : (message.attachmentUrl != null ? '📷 Photo' : ''),
          'lastMessageAt': FieldValue.serverTimestamp(),
          unreadField: FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left('Message Dispatch Fault: ${e.toString()}');
    }
  }

  // ── Chat Rooms ───────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatRoom>> streamChatRooms(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatRoomDto.fromFirestore(doc).toDomain())
            .toList());
  }

  @override
  Future<Either<String, String>> createOrGetChatRoom({
    required String buyerId,
    required String sellerId,
    required String buyerName,
    required String sellerName,
    String? buyerPhotoUrl,
    String? sellerPhotoUrl,
  }) async {
    try {
      final chatId = _roomId(buyerId, sellerId);
      final roomRef = _firestore.collection('chats').doc(chatId);
      final snap = await roomRef.get();

      if (!snap.exists) {
        final dto = ChatRoomDto(
          chatId: chatId,
          buyerId: buyerId,
          sellerId: sellerId,
          buyerName: buyerName,
          sellerName: sellerName,
          buyerPhotoUrl: buyerPhotoUrl,
          sellerPhotoUrl: sellerPhotoUrl,
          lastMessage: '',
          lastMessageAt: null,
          buyerUnread: 0,
          sellerUnread: 0,
        );
        await roomRef.set(dto.toMap());
      }
      return Right(chatId);
    } catch (e) {
      return Left('Chat Room Creation Fault: ${e.toString()}');
    }
  }

  @override
  Future<void> markRoomRead(String chatId, String userId) async {
    try {
      final roomSnap =
          await _firestore.collection('chats').doc(chatId).get();
      final buyerId = (roomSnap.data() ?? {})['buyerId'] as String? ?? '';
      final field = userId == buyerId ? 'buyerUnread' : 'sellerUnread';
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({field: 0});
    } catch (_) {}
  }

  @override
  Future<void> setTyping(
      String chatId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).set(
        {'typing_$userId': isTyping},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  @override
  Stream<bool> streamOtherTyping(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snap) {
      final data = snap.data() ?? {};
      final buyerId = data['buyerId'] as String? ?? '';
      final sellerId = data['sellerId'] as String? ?? '';
      final otherUserId = userId == buyerId ? sellerId : buyerId;
      return data['typing_$otherUserId'] as bool? ?? false;
    });
  }

  // ── Device Tokens ─────────────────────────────────────────────────────────

  @override
  Future<Either<String, Unit>> registerDevicePushToken(
      String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(token)
          .set({
        'pushToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'flutter_client',
      });
      return const Right(unit);
    } catch (e) {
      return Left('FCM Token Registration Failure: ${e.toString()}');
    }
  }
}