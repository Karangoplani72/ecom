import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/review.dart';

class ReviewDto {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String text;
  final List<String> photos;
  final bool verifiedPurchase;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const ReviewDto({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.photos,
    required this.verifiedPurchase,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ReviewDto(
      id: doc.id,
      productId: data['productId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      rating: (data['rating'] as num? ?? 0).toDouble(),
      text: data['text'] as String? ?? '',
      photos: List<String>.from((data['photos'] as List<dynamic>? ?? []).cast<String>()),
      verifiedPurchase: data['verifiedPurchase'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Review toDomain() {
    return Review(
      id: id,
      productId: productId,
      userId: userId,
      userName: userName,
      rating: rating,
      text: text,
      photos: photos,
      verifiedPurchase: verifiedPurchase,
      createdAt: createdAt?.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'text': text,
      'photos': photos,
      'verifiedPurchase': verifiedPurchase,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
