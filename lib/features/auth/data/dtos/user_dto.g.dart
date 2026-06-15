// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  uid: json['uid'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  activeStoreId: json['activeStoreId'] as String?,
  isActive: json['isActive'] as bool,
  createdAt: UserDto._timestampToDateTime(json['createdAt']),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'roles': instance.roles,
  'activeStoreId': instance.activeStoreId,
  'isActive': instance.isActive,
  'createdAt': UserDto._dateTimeToTimestamp(instance.createdAt),
};
