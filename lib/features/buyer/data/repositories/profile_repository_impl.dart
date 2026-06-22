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
      debugPrint('[PROFILE_UPLOAD] uploadProfileImage: Start flow');

      // 1. Get authenticated user
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(
          '[PROFILE_UPLOAD][ERROR] uploadProfileImage: No authenticated user found',
        );
        return left(const Failure('User not authenticated'));
      }
      final String userId = user.uid;
      debugPrint(
        '[PROFILE_UPLOAD] uploadProfileImage: Authenticated user uid=$userId',
      );

      // 2. Validate image type — by filename, not by a dart:io path (which
      // is a blob: URL with no extension on Flutter Web).
      if (!ImageUtils.isValidImageType(fileName)) {
        debugPrint(
          '[PROFILE_UPLOAD][ERROR] uploadProfileImage: Invalid image format',
        );
        return left(
          const Failure(
            'Invalid image type. Supported: JPG, JPEG, PNG, WEBP, GIF, BMP',
          ),
        );
      }

      // 3. Validate image size (Limit size to 5MB)
      if (!ImageUtils.isWithinSizeLimit(bytes, AppConstants.maxImageSizeMB)) {
        debugPrint(
          '[PROFILE_UPLOAD][ERROR] uploadProfileImage: Image size exceeds limit',
        );
        return left(
          Failure(
            'Image exceeds maximum size of ${AppConstants.maxImageSizeMB}MB',
          ),
        );
      }

      // 4. Compress image before upload
      debugPrint('[PROFILE_UPLOAD] uploadProfileImage: Compressing image...');
      final compressedBytes = await ImageUtils.compressImage(bytes);

      // 5. Upload to Cloudinary
      debugPrint(
        '[CLOUDINARY] uploadProfileImage: Uploading to Cloudinary folder user_profiles...',
      );
      final secureUrl = await CloudinaryService.uploadProfileImage(
        bytes: compressedBytes,
        userId: userId,
      );
      debugPrint(
        '[CLOUDINARY] uploadProfileImage: Upload successful, url=$secureUrl',
      );

      // 6. Save URL to Firestore
      // We update BOTH the 'users' collection (for existing integration)
      // AND the 'user_profiles' collection (as per new requirements).
      final cacheBustedUrl =
          '$secureUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      final batch = _firestore.batch();
      
      final userRef = _firestore.collection('users').doc(userId);
      final profileRef = _firestore.collection('user_profiles').doc(userId);

      batch.update(userRef, {
        'photoUrl': cacheBustedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(profileRef, {
        'photoUrl': cacheBustedUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));

      debugPrint(
        '[PROFILE_FIRESTORE] uploadProfileImage: Committing batch update...',
      );
      
      await batch.commit().timeout(AppConstants.firestoreTimeout);

      debugPrint(
        '[PROFILE_FIRESTORE][SUCCESS] uploadProfileImage: Firestore updated successfully',
      );

      return right(cacheBustedUrl);
    } on FirebaseException catch (e) {
      debugPrint(
        '[PROFILE_FIRESTORE][ERROR] Firestore error: ${e.code} - ${e.message}',
      );
      return left(ServerFailure('Database update failed: ${e.message}'));
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][ERROR] Unexpected failure: $e');
      return left(Failure('Failed to upload image: ${e.toString()}'));
    }
  }
}
