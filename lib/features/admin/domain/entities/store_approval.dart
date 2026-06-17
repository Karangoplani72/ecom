enum ApprovalStatus { applied, underReview, verified, rejected, suspended }

class StoreApproval {
  final String id;
  final String storeId;
  final String sellerId;
  final ApprovalStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  const StoreApproval({
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

  bool get isPending =>
      status == ApprovalStatus.applied || status == ApprovalStatus.underReview;

  bool get isApproved => status == ApprovalStatus.verified;

  bool get isRejected => status == ApprovalStatus.rejected;

  bool get isSuspended => status == ApprovalStatus.suspended;

  StoreApproval copyWith({
    String? id,
    String? storeId,
    String? sellerId,
    ApprovalStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
  }) {
    return StoreApproval(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }
}
