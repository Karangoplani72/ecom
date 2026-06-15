// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_assignment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryAssignmentDto _$DeliveryAssignmentDtoFromJson(
  Map<String, dynamic> json,
) => DeliveryAssignmentDto(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  deliveryAgentId: json['deliveryAgentId'] as String?,
  status: json['status'] as String,
  currentLatitude: (json['currentLatitude'] as num).toDouble(),
  currentLongitude: (json['currentLongitude'] as num).toDouble(),
  secureVerificationOtp: json['secureVerificationOtp'] as String,
  updatedTime: DeliveryAssignmentDto._timestampToDateTime(json['updatedTime']),
);

Map<String, dynamic> _$DeliveryAssignmentDtoToJson(
  DeliveryAssignmentDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'deliveryAgentId': instance.deliveryAgentId,
  'status': instance.status,
  'currentLatitude': instance.currentLatitude,
  'currentLongitude': instance.currentLongitude,
  'secureVerificationOtp': instance.secureVerificationOtp,
  'updatedTime': DeliveryAssignmentDto._dateTimeToTimestamp(
    instance.updatedTime,
  ),
};
