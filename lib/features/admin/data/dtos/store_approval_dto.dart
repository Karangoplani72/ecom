import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/store_approval.dart';

part 'store_approval_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class StoreApprovalDto {
  final String id;
  final String storeId;
  final String sellerId;
  final String status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  const StoreApprovalDto({
    required this.id,
    required this.storeId,
    required this.sellerId,
    required this.status,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  });

  factory StoreApprovalDto.fromJson(Map<String, dynamic> json) =>
      _$StoreApprovalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StoreApprovalDtoToJson(this);

  factory StoreApprovalDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return StoreApprovalDto(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      status: data['status'] ?? 'applied',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      notes: data['notes'],
    );
  }

  StoreApproval toDomain() {
    return StoreApproval(
      id: id,
      storeId: storeId,
      sellerId: sellerId,
      status: ApprovalStatus.values.byName(status),
      appliedAt: appliedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
      notes: notes,
    );
  }

  factory StoreApprovalDto.fromDomain(StoreApproval approval) {
    return StoreApprovalDto(
      id: approval.id,
      storeId: approval.storeId,
      sellerId: approval.sellerId,
      status: approval.status.name,
      appliedAt: approval.appliedAt,
      reviewedAt: approval.reviewedAt,
      reviewedBy: approval.reviewedBy,
      rejectionReason: approval.rejectionReason,
      notes: approval.notes,
    );
  }
}
