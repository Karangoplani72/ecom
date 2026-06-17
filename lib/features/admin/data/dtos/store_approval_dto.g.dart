// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_approval_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreApprovalDto _$StoreApprovalDtoFromJson(Map<String, dynamic> json) =>
    StoreApprovalDto(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      sellerId: json['sellerId'] as String,
      status: json['status'] as String,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$StoreApprovalDtoToJson(StoreApprovalDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'sellerId': instance.sellerId,
      'status': instance.status,
      'appliedAt': instance.appliedAt.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewedBy': instance.reviewedBy,
      'rejectionReason': instance.rejectionReason,
      'notes': instance.notes,
    };
