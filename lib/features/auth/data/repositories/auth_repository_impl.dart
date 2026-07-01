import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/auth/data/dtos/user_dto.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({required this._firebaseAuth, required this._firestore});

  /// Stream authentication state changes with user data sync
  @override
  Stream<Option<AppUser>> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return const None();
      }

      try {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (!doc.exists) {
          await _createUserProfile(firebaseUser);

          final freshDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

          if (!freshDoc.exists) {
            return const None();
          }

          return Some(UserDto.fromFirestore(freshDoc).toDomain());
        }

        return Some(UserDto.fromFirestore(doc).toDomain());
      } catch (e, stackTrace) {
        debugPrint('Auth sync error: $e');
        debugPrintStack(stackTrace: stackTrace);

        return const None();
      }
    });
  }

  /// Sign in with email and password
  @override
  Future<Either<String, AppUser>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        return const Left('Email cannot be empty');
      }
      if (password.isEmpty) {
        return const Left('Password cannot be empty');
      }

      // Sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Left('Authentication failed: User profile not found');
      }

      // Fetch user document from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) {
        return const Left('User profile not found in database');
      }

      final userDto = UserDto.fromFirestore(doc);
      return Right(userDto.toDomain());
    } on firebase_auth.FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e.code);
      return Left(errorMessage);
    } catch (e) {
      return Left('Login failed: ${e.toString()}');
    }
  }

  /// Sign up new user with email and password
  @override
  Future<Either<String, AppUser>> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        return const Left('Email cannot be empty');
      }
      if (password.length < 6) {
        return const Left('Password must be at least 6 characters');
      }
      if (displayName.trim().isEmpty) {
        return const Left('Display name cannot be empty');
      }

      // Create user account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        return const Left('Account creation failed');
      }

      // Create user profile in Firestore
      final userId = credential.user!.uid;
      final now = DateTime.now();

      // Check for pending store staff invitation
      final inviteSnapshot = await _firestore
          .collection('store_invitations')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      String? invitedStoreId;
      final userRoles = <String>['buyer'];

      if (inviteSnapshot.docs.isNotEmpty) {
        final inviteData = inviteSnapshot.docs.first.data();
        invitedStoreId = inviteData['storeId'] as String?;
        userRoles.add('storeManager');
        // Delete invitation now that it is accepted
        await inviteSnapshot.docs.first.reference.delete();
      }

      final userProfile = {
        'uid': userId,
        'email': email.trim(),
        'displayName': displayName.trim(),
        'roles': userRoles,
        'storeId': invitedStoreId,
        'isActive': true,
        'sellerApproved': false,
        'sellerApplicationStatus': 'none',
        'walletBalance': 0.0,
        'phoneNumber': '',
        'photoUrl': null,
        'address': '',
        'city': '',
        'state': '',
        'pincode': '',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastLoginAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('users').doc(userId).set(userProfile);

      if (invitedStoreId != null) {
        await _firestore
            .collection('stores')
            .doc(invitedStoreId)
            .collection('staff')
            .doc(userId)
            .set({
          'email': email.trim(),
          'displayName': displayName.trim(),
          'role': 'storeManager',
          'joinedAt': Timestamp.fromDate(now),
        });
      }

      final userDto = UserDto.fromJson(userProfile);
      return Right(userDto.toDomain());
    } on firebase_auth.FirebaseAuthException catch (e) {
      final errorMessage = _getFirebaseAuthErrorMessage(e.code);
      return Left(errorMessage);
    } catch (e) {
      return Left('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign out the current user
  @override
  Future<Either<String, Unit>> signOut() async {
    try {
      // Update last logout timestamp
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
      }

      // Sign out
      await _firebaseAuth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current user session
  @override
  Future<Either<String, AppUser>> getCurrentUserSession() async {
    try {
      final activeUser = _firebaseAuth.currentUser;
      if (activeUser == null) {
        return const Left('No active user session');
      }

      // Fetch fresh user data from Firestore
      final doc = await _firestore
          .collection('users')
          .doc(activeUser.uid)
          .get();

      if (!doc.exists) {
        return const Left('User profile not found');
      }

      final userDto = UserDto.fromFirestore(doc);

      // Update last seen timestamp
      await _firestore.collection('users').doc(activeUser.uid).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });

      return Right(userDto.toDomain());
    } catch (e) {
      return Left('Failed to fetch user session: ${e.toString()}');
    }
  }

  /// Auto-create user profile in Firestore
  Future<void> _createUserProfile(firebase_auth.User firebaseUser) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': firebaseUser.displayName ?? '',
        'roles': ['buyer'],
        'isActive': true,
        'sellerApproved': false,
        'walletBalance': 0.0,
        'phoneNumber': firebaseUser.phoneNumber ?? '',
        'photoUrl': firebaseUser.photoURL,
        'address': '',
        'city': '',
        'state': '',
        'pincode': '',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastLoginAt': Timestamp.fromDate(now),
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to create user profile: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Map Firebase Auth error codes to user-friendly messages
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'account-exists-with-different-credential':
        return 'Account already exists with different credentials';
      default:
        return 'Authentication error: $code';
    }
  }

  /// Update user profile
  @override
  Future<Either<String, Unit>> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Never allow privilege escalation
      updates.remove('roles');
      updates.remove('isActive');
      updates.remove('walletBalance');

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updates);
      return const Right(unit);
    } catch (e) {
      return Left('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> updateFCMToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(unit);
    } catch (e) {
      return Left('Failed to update FCM token: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(e.message ?? 'Failed to send password reset email');
    } catch (e) {
      return Left('Failed to send password reset email: ${e.toString()}');
    }
  }
}
