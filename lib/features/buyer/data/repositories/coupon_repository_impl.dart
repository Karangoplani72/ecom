import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/common_providers.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../dtos/coupon_dto.dart';

part 'coupon_repository_impl.g.dart';

class CouponRepositoryImpl implements CouponRepository {
  final FirebaseFirestore _firestore;

  CouponRepositoryImpl(this._firestore);

  @override
  Future<Either<String, Coupon>> validateCoupon(
    String code, {
    String? userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return left('Invalid or expired coupon code.');
      }

      final doc = snapshot.docs.first;
      final coupon = CouponDto.fromFirestore(doc).toDomain();

      if (!coupon.isActive) {
        return left('This coupon is no longer active.');
      }

      if (coupon.expiryDate != null &&
          coupon.expiryDate!.isBefore(DateTime.now())) {
        return left('This coupon has expired.');
      }

      // Total usage limit check
      if (coupon.totalUsageLimit > 0 &&
          coupon.usageCount >= coupon.totalUsageLimit) {
        return left('This coupon has reached its usage limit.');
      }

      // Per-user limit check
      if (coupon.usageLimitPerUser > 0 && userId != null) {
        final userUses = coupon.usedBy.where((uid) => uid == userId).length;
        if (userUses >= coupon.usageLimitPerUser) {
          return left(
            'You have already used this coupon the maximum number of times.',
          );
        }
      }

      // First order only check
      if (coupon.isFirstOrderOnly) {
        if (userId == null) {
          return left('You must be logged in to use this coupon.');
        }
        final ordersSnapshot = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        if (ordersSnapshot.docs.isNotEmpty) {
          return left('This coupon is only valid for your first order.');
        }
      }

      return right(coupon);
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to validate coupon.');
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, Unit>> redeemCoupon(
    String couponId,
    String userId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final couponRef = _firestore.collection('coupons').doc(couponId);
        final couponDoc = await transaction.get(couponRef);

        if (!couponDoc.exists) throw Exception('Coupon not found');

        final coupon = CouponDto.fromFirestore(couponDoc).toDomain();

        // Re-validate atomically
        if (!coupon.isActive) throw Exception('Coupon is no longer active');
        if (coupon.expiryDate != null &&
            coupon.expiryDate!.isBefore(DateTime.now())) {
          throw Exception('Coupon has expired');
        }
        if (coupon.totalUsageLimit > 0 &&
            coupon.usageCount >= coupon.totalUsageLimit) {
          throw Exception('Coupon usage limit reached');
        }
        final userUses = coupon.usedBy.where((uid) => uid == userId).length;
        if (coupon.usageLimitPerUser > 0 &&
            userUses >= coupon.usageLimitPerUser) {
          throw Exception('You have already used this coupon');
        }

        // We skip the first-order query in the transaction to avoid complex cross-collection transaction rules,
        // as the initial validation check should be sufficient for most cases.

        transaction.update(couponRef, {
          'usageCount': FieldValue.increment(1),
          'usedBy': FieldValue.arrayUnion([userId]),
        });
      });
      return right(unit);
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to redeem coupon');
    } catch (e) {
      return left(e.toString());
    }
  }
}

@riverpod
CouponRepository couponRepository(Ref ref) {
  return CouponRepositoryImpl(ref.watch(firebaseFirestoreProvider));
}
