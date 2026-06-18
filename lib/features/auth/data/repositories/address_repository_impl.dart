import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/user_address.dart';
import '../../domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final FirebaseFirestore _firestore;

  AddressRepositoryImpl({required this._firestore});

  @override
  Stream<List<UserAddress>> watchAddresses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserAddress.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<Either<String, Unit>> addAddress(
    String userId,
    UserAddress address,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc();

      final data = address.toMap();

      if (address.isDefault) {
        await _clearDefault(userId);
      }

      await docRef.set(data);
      return const Right(unit);
    } catch (e) {
      return Left('Failed to add address: $e');
    }
  }

  @override
  Future<Either<String, Unit>> updateAddress(
    String userId,
    UserAddress address,
  ) async {
    try {
      if (address.isDefault) {
        await _clearDefault(userId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update address: $e');
    }
  }

  @override
  Future<Either<String, Unit>> deleteAddress(
    String userId,
    String addressId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      return const Right(unit);
    } catch (e) {
      return Left('Failed to delete address: $e');
    }
  }

  @override
  Future<Either<String, Unit>> setDefaultAddress(
    String userId,
    String addressId,
  ) async {
    try {
      await _clearDefault(userId);
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});
      return const Right(unit);
    } catch (e) {
      return Left('Failed to set default address: $e');
    }
  }

  Future<void> _clearDefault(String userId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    await batch.commit();
  }
}
