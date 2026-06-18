import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/seller_store.dart';

class SellerStoreDto {
  final String id;
  final String sellerId;
  final String storeName;
  final String? logoUrl;
  final String? bannerUrl;
  final bool isActive;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SellerStoreDto({
    required this.id,
    required this.sellerId,
    required this.storeName,
    this.logoUrl,
    this.bannerUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerStoreDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SellerStoreDto(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      bannerUrl: data['bannerUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  SellerStore toDomain() {
    return SellerStore(
      id: id,
      sellerId: sellerId,
      storeName: storeName,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      isActive: isActive,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'storeName': storeName,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  SellerStoreDto copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? logoUrl,
    String? bannerUrl,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SellerStoreDto(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      storeName: storeName ?? this.storeName,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerStoreDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sellerId == other.sellerId &&
          storeName == other.storeName &&
          logoUrl == other.logoUrl &&
          bannerUrl == other.bannerUrl &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      sellerId.hashCode ^
      storeName.hashCode ^
      logoUrl.hashCode ^
      bannerUrl.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'SellerStoreDto(id: $id, sellerId: $sellerId, '
        'storeName: $storeName, isActive: $isActive)';
  }
}
