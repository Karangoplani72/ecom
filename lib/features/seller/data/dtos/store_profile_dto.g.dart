// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreProfileDto _$StoreProfileDtoFromJson(Map<String, dynamic> json) =>
    StoreProfileDto(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      logoUrl: json['logoUrl'] as String,
      averageRating: (json['averageRating'] as num).toDouble(),
      status: json['status'] as String,
      operationalHours: (json['operationalHours'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      fallbackCategoryTags: (json['fallbackCategoryTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$StoreProfileDtoToJson(StoreProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sellerId': instance.sellerId,
      'name': instance.name,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'averageRating': instance.averageRating,
      'status': instance.status,
      'operationalHours': instance.operationalHours,
      'fallbackCategoryTags': instance.fallbackCategoryTags,
    };
