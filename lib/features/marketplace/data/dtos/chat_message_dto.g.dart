// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    ChatMessageDto(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
      type: json['type'] as String,
      timestamp: ChatMessageDto._timestampToDateTime(json['timestamp']),
      isRead: json['isRead'] as bool,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
    );

Map<String, dynamic> _$ChatMessageDtoToJson(ChatMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'senderId': instance.senderId,
      'text': instance.text,
      'type': instance.type,
      'timestamp': ChatMessageDto._dateTimeToTimestamp(instance.timestamp),
      'isRead': instance.isRead,
      'attachmentUrl': instance.attachmentUrl,
      'attachmentName': instance.attachmentName,
    };
