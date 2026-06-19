// lib/features/seller/data/repositories/seller_application_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/seller_application.dart';
import '../../domain/repositories/seller_application_repository.dart';
import '../dtos/seller_application_dto.dart';

class SellerApplicationRepositoryImpl implements SellerApplicationRepository {
  final FirebaseFirestore _firestore;

  static const _collection = SellerApplicationDto.collectionPath;

  SellerApplicationRepositoryImpl({required this._firestore});

  @override
  Future<Either<String, Unit>> submitApplication(
    SellerApplication application,
  ) async {
    try {
      final docRef = _firestore.collection(_collection).doc(application.userId);
      final existing = await docRef.get();

      if (existing.exists) {
        final currentStatus = existing.data()?['status'] as String?;
        if (currentStatus == 'pending') {
          return const Left(
            'You already have a pending seller application. Please wait for review.',
          );
        }
      }

      final dto = SellerApplicationDto.fromDomain(application);

      final batch = _firestore.batch();
      
      // Save application
      batch.set(docRef, dto.toFirestore()..['status'] = 'pending');

      // Update user application status
      batch.update(_firestore.collection('users').doc(application.userId), {
        'sellerApplicationStatus': 'pending',
      });

      await batch.commit();

      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(e.message ?? 'Failed to submit application.');
    } catch (e) {
      return Left(e.toString());
    }
  }
}
