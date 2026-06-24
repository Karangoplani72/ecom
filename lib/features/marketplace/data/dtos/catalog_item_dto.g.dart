// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogItemDto _$CatalogItemDtoFromJson(Map<String, dynamic> json) =>
    CatalogItemDto(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      basePrice: (json['basePrice'] as num).toDouble(),
      currency: json['currency'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CatalogItemDtoToJson(CatalogItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'title': instance.title,
      'description': instance.description,
      'type': instance.type,
      'status': instance.status,
      'basePrice': instance.basePrice,
      'currency': instance.currency,
      'imageUrls': instance.imageUrls,
      'variants': instance.variants,
      'metadata': instance.metadata,
    };
