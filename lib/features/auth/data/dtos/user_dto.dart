import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/app_user.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  final String uid;
  final String email;
  final String phoneNumber;
  final List<String> roles;
  final String? activeStoreId;
  final bool isActive;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  UserDto({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.roles,
    this.activeStoreId,
    required this.isActive,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  // Firestore DocumentSnapshot deserialization hook
  factory UserDto.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception("Target User Document does not exist at infrastructure layer.");
    }
    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = doc.id;
    return UserDto.fromJson(data);
  }

  // Domain Entity conversion mapping
  AppUser toDomain() {
    return AppUser(
      uid: uid,
      email: email,
      phoneNumber: phoneNumber,
      roles: roles.map((r) => UserRole.values.byName(r)).toList(),
      activeStoreId: activeStoreId,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static DateTime _timestampToDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.parse(val);
    return DateTime.now();
  }

  static dynamic _dateTimeToTimestamp(DateTime date) => Timestamp.fromDate(date);
}