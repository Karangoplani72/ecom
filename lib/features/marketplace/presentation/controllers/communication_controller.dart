import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/marketplace/data/repositories/communication_repository_impl.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';
import 'package:ecom/features/marketplace/domain/repositories/communication_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'communication_controller.g.dart';

@riverpod
CommunicationRepository communicationRepository(Ref ref) {
  return CommunicationRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<List<ChatMessage>> liveMessageStream(Ref ref, String roomId) {
  return ref.watch(communicationRepositoryProvider).streamRoomMessages(roomId);
}

@riverpod
class CommunicationController extends _$CommunicationController {
  @override
  FutureOr<void> build() {
    return null;
  }

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

  Future<void> associateDeviceToken(String userId, String token) async {
    final repo = ref.read(communicationRepositoryProvider);

    await repo.registerDevicePushToken(userId, token);
  }
}
