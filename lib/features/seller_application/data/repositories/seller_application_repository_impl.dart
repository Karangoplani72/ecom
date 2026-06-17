// lib/features/seller/data/repositories/seller_application_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_application.dart';
import '../../domain/repositories/seller_application_repository.dart';
import '../dtos/seller_application_dto.dart';

class SellerApplicationRepositoryImpl implements SellerApplicationRepository {
  final FirebaseFirestore _firestore;

  static const _collection = 'storeApplications';

  SellerApplicationRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, Unit>> submitApplication(
    SellerApplication application,
  ) async {
    try {
      // Check for existing pending application
      final existing = await _firestore
          .collection(_collection)
          .where('sellerId', isEqualTo: application.sellerId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return const Left(
          'You already have a pending seller application. Please wait for review.',
        );
      }

      final dto = SellerApplicationDto.fromDomain(application);
      await _firestore.collection(_collection).add(dto.toFirestore());

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Failed to submit application.');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
