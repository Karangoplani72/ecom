import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/marketplace/domain/entities/chat_message.dart';

part 'chat_message_dto.g.dart';

@JsonSerializable()
class ChatMessageDto {
  final String id;
  final String roomId;
  final String senderId;
  final String text;
  final String type;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime timestamp;
  final bool isRead;

  ChatMessageDto({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) => _$ChatMessageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageDtoToJson(this);

  factory ChatMessageDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ChatMessageDto.fromJson(data);
  }

  ChatMessage toDomain() {
    return ChatMessage(
      id: id,
      roomId: roomId,
      senderId: senderId,
      text: text,
      type: MessageType.values.byName(type),
      timestamp: timestamp,
      isRead: isRead,
    );
  }

  static DateTime _timestampToDateTime(dynamic val) => (val is Timestamp) ? val.toDate() : DateTime.now();
  static dynamic _dateTimeToTimestamp(DateTime date) => Timestamp.fromDate(date);
}