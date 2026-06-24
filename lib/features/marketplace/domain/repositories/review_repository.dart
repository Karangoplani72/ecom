import 'package:fpdart/fpdart.dart';

import '../entities/review.dart';

abstract class ReviewRepository {
  /// Fetch reviews for a specific product
  Future<Either<String, List<Review>>> getProductReviews(String productId, {int limit = 10, String? startAfterId});

  /// Submit a new review
  Future<Either<String, Review>> submitReview(Review review);

  /// Delete a review
  Future<Either<String, void>> deleteReview(String reviewId);
}
