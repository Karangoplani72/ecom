import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/marketplace/data/repositories/communication_repository_impl.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_room.dart';
import 'package:ecom/features/marketplace/domain/repositories/communication_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'communication_controller.g.dart';

@riverpod
CommunicationRepository communicationRepository(Ref ref) {
  return CommunicationRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

// ── Message stream for a single chat room ────────────────────────────────────

@riverpod
Stream<List<ChatMessage>> liveMessageStream(Ref ref, String roomId) {
  return ref.watch(communicationRepositoryProvider).streamRoomMessages(roomId);
}

// ── Chat rooms stream for the current user ───────────────────────────────────

@riverpod
Stream<List<ChatRoom>> chatRoomsStream(Ref ref, String userId) {
  return ref.watch(communicationRepositoryProvider).streamChatRooms(userId);
}

// ── Typing indicator stream ───────────────────────────────────────────────────

@riverpod
Stream<bool> otherTypingStream(Ref ref, String chatId, String userId) {
  return ref
      .watch(communicationRepositoryProvider)
      .streamOtherTyping(chatId, userId);
}

// ── Main controller ──────────────────────────────────────────────────────────

@riverpod
class CommunicationController extends _$CommunicationController {
  @override
  FutureOr<void> build() {
    return null;
  }

  /// Send a plain-text message in [roomId] from [senderId].
  Future<void> transmitText(
    String roomId,
    String senderId,
    String plainText,
  ) async {
    final repo = ref.read(communicationRepositoryProvider);

    final message = ChatMessage(
      id: '',
      roomId: roomId,
      senderId: senderId,
      text: plainText,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final result = await repo.dispatchLiveMessage(roomId, message);

    if (result.isLeft()) {
      state = AsyncValue.error(
        result.fold((error) => error, (_) => ''),
        StackTrace.current,
      );
    }
  }

  /// Create or retrieve the chat room between buyer ↔ seller.
  /// Returns the chatId on success.
  Future<String?> createOrGetRoom({
    required String buyerId,
    required String sellerId,
    required String buyerName,
    required String sellerName,
    String? buyerPhotoUrl,
    String? sellerPhotoUrl,
  }) async {
    final repo = ref.read(communicationRepositoryProvider);
    final result = await repo.createOrGetChatRoom(
      buyerId: buyerId,
      sellerId: sellerId,
      buyerName: buyerName,
      sellerName: sellerName,
      buyerPhotoUrl: buyerPhotoUrl,
      sellerPhotoUrl: sellerPhotoUrl,
    );
    return result.fold((err) {
      state = AsyncValue.error(err, StackTrace.current);
      return null;
    }, (chatId) => chatId);
  }

  /// Mark all messages in [chatId] as read for [userId].
  Future<void> markRead(String chatId, String userId) async {
    await ref.read(communicationRepositoryProvider).markRoomRead(chatId, userId);
  }

  /// Update the typing indicator for [userId] in [chatId].
  Future<void> setTyping(
      String chatId, String userId, bool isTyping) async {
    await ref
        .read(communicationRepositoryProvider)
        .setTyping(chatId, userId, isTyping);
  }

  Future<void> associateDeviceToken(String userId, String token) async {
    final repo = ref.read(communicationRepositoryProvider);
    await repo.registerDevicePushToken(userId, token);
  }
}
