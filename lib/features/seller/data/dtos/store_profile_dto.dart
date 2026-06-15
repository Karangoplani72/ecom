import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ecom/features/seller/domain/entities/store_profile.dart';

part 'store_profile_dto.g.dart';

@JsonSerializable(explicitToJson: true)
class StoreProfileDto {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String logoUrl;
  final double averageRating;
  final String status;
  final Map<String, List<String>> operationalHours;
  final List<String> fallbackCategoryTags;

  StoreProfileDto({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.averageRating,
    required this.status,
    required this.operationalHours,
    required this.fallbackCategoryTags,
  });

  factory StoreProfileDto.fromJson(Map<String, dynamic> json) => _$StoreProfileDtoFromJson(json);
  Map<String, dynamic> toJson() => _$StoreProfileDtoToJson(this);

  factory StoreProfileDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return StoreProfileDto.fromJson(data);
  }

  StoreProfile toDomain() {
    return StoreProfile(
      id: id,
      sellerId: sellerId,
      name: name,
      description: description,
      logoUrl: logoUrl,
      averageRating: averageRating,
      status: VerificationStatus.values.byName(status),
      operationalHours: operationalHours,
      fallbackCategoryTags: fallbackCategoryTags,
    );
  }
}