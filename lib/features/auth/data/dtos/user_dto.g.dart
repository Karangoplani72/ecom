// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  uid: json['uid'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  photoUrl: json['photoUrl'] as String?,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  isActive: json['isActive'] as bool,
  sellerApproved: json['sellerApproved'] as bool? ?? false,
  createdAt: UserDto._timestampToDateTime(json['createdAt']),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'roles': instance.roles,
  'isActive': instance.isActive,
  'sellerApproved': instance.sellerApproved,
  'createdAt': UserDto._dateTimeToTimestamp(instance.createdAt),
};
