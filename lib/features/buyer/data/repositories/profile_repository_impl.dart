import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileRepositoryImpl({required this._auth, required this._firestore});

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      debugPrint('[PROFILE_UPLOAD] Start flow');

      final user = _auth.currentUser;
      if (user == null) {
        return left(const Failure('User not authenticated'));
      }
      final userId = user.uid;
      debugPrint('[PROFILE_UPLOAD] userId=$userId');

      if (!ImageUtils.isValidImageType(fileName)) {
        return left(
          const Failure(
            'Invalid image type. Supported: JPG, JPEG, PNG, WEBP, GIF, BMP',
          ),
        );
      }

      if (!ImageUtils.isWithinSizeLimit(bytes, AppConstants.maxImageSizeMB)) {
        return left(
          Failure(
            'Image exceeds maximum size of ${AppConstants.maxImageSizeMB}MB',
          ),
        );
      }

      debugPrint('[PROFILE_UPLOAD] Compressing...');
      final compressedBytes = await ImageUtils.compressImage(bytes);

      // Signed upload — deletes old image then uploads fresh.
      // version param not needed: signed destroy+upload guarantees fresh CDN asset.
      final version = DateTime.now().millisecondsSinceEpoch;
      final secureUrl = await CloudinaryService.uploadProfileImage(
        bytes: compressedBytes,
        userId: userId,
        version: version,
      );
      debugPrint('[CLOUDINARY][SUCCESS] url=$secureUrl');

      // Persist to Firestore
      final batch = _firestore.batch();

      batch.update(_firestore.collection('users').doc(userId), {
        'photoUrl': secureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        _firestore.collection('user_profiles').doc(userId),
        {
          'photoUrl': secureUrl,
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': userId,
        },
        SetOptions(merge: true),
      );

      await batch.commit().timeout(AppConstants.firestoreTimeout);
      debugPrint('[PROFILE_FIRESTORE][SUCCESS] Firestore updated: $secureUrl');

      return right(secureUrl);
    } on FirebaseException catch (e) {
      debugPrint('[PROFILE_FIRESTORE][ERROR] ${e.code}: ${e.message}');
      return left(ServerFailure('Database update failed: ${e.message}'));
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][ERROR] $e');
      return left(Failure('Failed to upload image: ${e.toString()}'));
    }
  }
}
