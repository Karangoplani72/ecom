import 'package:fpdart/fpdart.dart';

import '../entities/user_address.dart';

abstract class AddressRepository {
  Stream<List<UserAddress>> watchAddresses(String userId);
  Future<Either<String, Unit>> addAddress(String userId, UserAddress address);
  Future<Either<String, Unit>> updateAddress(
    String userId,
    UserAddress address,
  );
  Future<Either<String, Unit>> deleteAddress(String userId, String addressId);
  Future<Either<String, Unit>> setDefaultAddress(
    String userId,
    String addressId,
  );
}
