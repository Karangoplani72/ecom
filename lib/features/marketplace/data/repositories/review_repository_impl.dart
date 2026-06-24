import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';


import '../../../../core/providers/common_providers.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../dtos/review_dto.dart';

part 'review_repository_impl.g.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepositoryImpl(this._firestore);

  @override
  Future<Either<String, List<Review>>> getProductReviews(String productId, {int limit = 10, String? startAfterId}) async {
    try {
      Query query = _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfterId != null) {
        final startDoc = await _firestore.collection('reviews').doc(startAfterId).get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }

      final snapshot = await query.get();
      final reviews = snapshot.docs
          .map((doc) => ReviewDto.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>).toDomain())
          .toList();

      return right(reviews);
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to fetch reviews');
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, Review>> submitReview(Review review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final reviewDto = ReviewDto(
        id: docRef.id,
        productId: review.productId,
        userId: review.userId,
        userName: review.userName,
        rating: review.rating,
        text: review.text,
        photos: review.photos,
        verifiedPurchase: review.verifiedPurchase,
      );

      await docRef.set(reviewDto.toFirestore());

      // Fetch the newly created document to ensure timestamp is hydrated
      final newDoc = await docRef.get();
      return right(ReviewDto.fromFirestore(newDoc).toDomain());
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to submit review');
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to delete review');
    } catch (e) {
      return left(e.toString());
    }
  }
}

@riverpod
ReviewRepository reviewRepository(Ref ref) {
  return ReviewRepositoryImpl(ref.watch(firebaseFirestoreProvider));
}
