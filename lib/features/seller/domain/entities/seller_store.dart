import 'package:flutter/foundation.dart';

@immutable
class SellerStore {
  final String id;
  final String sellerId;
  final String storeName;
  final String? logoUrl;
  final String? bannerUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerStore({
    required this.id,
    required this.sellerId,
    required this.storeName,
    this.logoUrl,
    this.bannerUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;

  bool get hasBanner => bannerUrl != null && bannerUrl!.isNotEmpty;

  SellerStore copyWith({
    String? id,
    String? sellerId,
    String? storeName,
    String? logoUrl,
    String? bannerUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerStore(
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
      other is SellerStore &&
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
    return 'SellerStore(id: $id, storeName: $storeName, isActive: $isActive)';
  }
}
