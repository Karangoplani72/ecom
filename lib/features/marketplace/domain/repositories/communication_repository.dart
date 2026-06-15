import 'package:fpdart/fpdart.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';

abstract class CommunicationRepository {
  Stream<List<ChatMessage>> streamRoomMessages(String roomId, {int limit});
  Future<Either<String, Unit>> dispatchLiveMessage(String roomId, ChatMessage message);
  Future<Either<String, Unit>> registerDevicePushToken(String userId, String token);
}