// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute_ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisputeTicketDto _$DisputeTicketDtoFromJson(Map<String, dynamic> json) =>
    DisputeTicketDto(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      reporterId: json['reporterId'] as String,
      reportedStoreId: json['reportedStoreId'] as String,
      reason: json['reason'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      assignedAgentId: json['assignedAgentId'] as String?,
      createdAt: DisputeTicketDto._timestampToDateTime(json['createdAt']),
    );

Map<String, dynamic> _$DisputeTicketDtoToJson(DisputeTicketDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transactionId': instance.transactionId,
      'reporterId': instance.reporterId,
      'reportedStoreId': instance.reportedStoreId,
      'reason': instance.reason,
      'priority': instance.priority,
      'status': instance.status,
      'assignedAgentId': instance.assignedAgentId,
      'createdAt': DisputeTicketDto._dateTimeToTimestamp(instance.createdAt),
    };
