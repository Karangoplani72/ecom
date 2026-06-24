class AuditLog {
  final String id;
  final String action;
  final String userId;
  final String userEmail;
  final String targetId;
  final String targetType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.action,
    required this.userId,
    required this.userEmail,
    required this.targetId,
    required this.targetType,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json, String id) {
    return AuditLog(
      id: id,
      action: json['action'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
