import 'package:cloud_firestore/cloud_firestore.dart';

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
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  /// Safely converts Firestore Timestamp, ISO String, or null → DateTime.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// toJson for Firestore writes.
  /// NOTE: callers should merge {'createdAt': FieldValue.serverTimestamp()}
  /// instead of relying on the ISO string in this map.
  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'targetId': targetId,
      'targetType': targetType,
      'metadata': metadata,
      // createdAt intentionally omitted — repository injects FieldValue.serverTimestamp()
    };
  }
}
