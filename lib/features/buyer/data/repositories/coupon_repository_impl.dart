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
  Future<Either<String, Coupon>> validateCoupon(String code) async {
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
      final coupon = CouponDto.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>).toDomain();

      if (!coupon.isActive) {
        return left('This coupon is no longer active.');
      }

      if (coupon.expiryDate.isBefore(DateTime.now())) {
        return left('This coupon has expired.');
      }

      return right(coupon);
    } on FirebaseException catch (e) {
      return left(e.message ?? 'Failed to validate coupon.');
    } catch (e) {
      return left(e.toString());
    }
  }
}

@riverpod
CouponRepository couponRepository(Ref ref) {
  return CouponRepositoryImpl(ref.watch(firebaseFirestoreProvider));
}
