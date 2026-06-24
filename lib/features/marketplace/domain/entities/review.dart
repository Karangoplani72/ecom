import 'package:flutter/foundation.dart';

@immutable
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String text;
  final List<String> photos;
  final bool verifiedPurchase;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    this.photos = const [],
    this.verifiedPurchase = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          userId == other.userId &&
          userName == other.userName &&
          rating == other.rating &&
          text == other.text &&
          listEquals(photos, other.photos) &&
          verifiedPurchase == other.verifiedPurchase &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      productId.hashCode ^
      userId.hashCode ^
      userName.hashCode ^
      rating.hashCode ^
      text.hashCode ^
      Object.hashAll(photos) ^
      verifiedPurchase.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    double? rating,
    String? text,
    List<String>? photos,
    bool? verifiedPurchase,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      photos: photos ?? this.photos,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, productId: $productId, userId: $userId, rating: $rating)';
  }
}
