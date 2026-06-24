import 'package:fpdart/fpdart.dart';

import '../entities/coupon.dart';

abstract class CouponRepository {
  Future<Either<String, Coupon>> validateCoupon(String code);
}
