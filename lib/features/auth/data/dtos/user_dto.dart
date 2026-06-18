import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../seller/domain/entities/store_profile.dart';
import '../../domain/entities/app_user.dart';

part 'user_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class UserDto {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  final List<String> roles;

  final bool isActive;

  @JsonKey(defaultValue: false)
  final bool sellerApproved;

  @JsonKey(fromJson: _timestampToDateTime, toJson: _dateTimeToTimestamp)
  final DateTime createdAt;

  const UserDto({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.roles,
    required this.isActive,
    this.sellerApproved = false,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  factory UserDto.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      throw Exception(
        'Target User Document does not exist at infrastructure layer.',
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    data['uid'] = doc.id;

    return UserDto.fromJson(data);
  }

  AppUser toDomain() {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      roles: roles.map((r) => UserRole.values.byName(r)).toList(),
      verificationStatus: VerificationStatus.pending,
      isActive: isActive,
      sellerApproved: sellerApproved,
      createdAt: createdAt,
    );
  }

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static dynamic _dateTimeToTimestamp(DateTime date) =>
      Timestamp.fromDate(date);
}
