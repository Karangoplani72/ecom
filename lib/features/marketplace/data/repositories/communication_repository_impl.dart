import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/repositories/communication_repository.dart';
import 'package:ecom/features/marketplace/data/dtos/chat_message_dto.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  final FirebaseFirestore _firestore;

  CommunicationRepositoryImpl({required this._firestore});

  @override
  Stream<List<ChatMessage>> streamRoomMessages(String roomId, {int limit = 50}) {
    // Open an efficient websocket transaction stream directly to the chat room
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessageDto.fromFirestore(doc).toDomain())
        .toList());
  }

  @override
  Future<Either<String, Unit>> dispatchLiveMessage(String roomId, ChatMessage message) async {
    try {
      final messageMap = ChatMessageDto(
        id: '',
        roomId: roomId,
        senderId: message.senderId,
        text: message.text,
        type: message.type.name,
        timestamp: message.timestamp,
        isRead: false,
      ).toJson();

      // Remove placeholder ID so Firestore auto-generates an optimized key
      messageMap.remove('id');

      await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .add(messageMap);

      return const Right(unit);
    } catch (e) {
      return Left("Message Dispatch Fault: ${e.toString()}");
    }
  }

  @override
  Future<Either<String, Unit>> registerDevicePushToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).collection('tokens').doc(token).set({
        'pushToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'flutter_client',
      });
      return const Right(unit);
    } catch (e) {
      return Left("FCM Token Registration Failure: ${e.toString()}");
    }
  }
}