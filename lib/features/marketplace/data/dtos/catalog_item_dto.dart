import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/catalog_item.dart';

part 'catalog_item_dto.g.dart';

@JsonSerializable()
class CatalogItemDto {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String type;
  final String status;
  final double basePrice;
  final String currency;
  final List<String> imageUrls;
  final List<Map<String, dynamic>> variants;
  final Map<String, dynamic> metadata;

  CatalogItemDto({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.currency,
    required this.imageUrls,
    this.variants = const [],
    required this.metadata,
  });

  factory CatalogItemDto.fromJson(Map<String, dynamic> json) => _$CatalogItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CatalogItemDtoToJson(this);

  factory CatalogItemDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return CatalogItemDto.fromJson(data);
  }

  CatalogItem toDomain() {
    return CatalogItem(
      id: id,
      storeId: storeId,
      title: title,
      description: description,
      type: CatalogType.values.byName(type),
      status: ListingStatus.values.byName(status),
      basePrice: basePrice,
      currency: currency,
      imageUrls: imageUrls,
      variants: variants,
      metadata: metadata,
    );
  }
}