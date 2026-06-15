import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ecom/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/domain/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    firebaseAuth: f_auth.FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
Stream<AppUser?> authStateSignaling(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges.map(
        (option) => option.fold(() => null, (user) => user),
  );
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<AppUser?> build() async {
    final sessionResult = await ref.read(authRepositoryProvider).getCurrentUserSession();
    return sessionResult.fold((failure) => null, (user) => user);
  }

  // --- NEW: Automated Store Provisioning ---
  Future<void> _ensureStoreExists(String uid) async {
    final storeRef = FirebaseFirestore.instance.collection('stores').doc(uid);
    final snapshot = await storeRef.get();

    if (!snapshot.exists) {
      await storeRef.set({
        'sellerId': uid,
        'name': 'My New Store',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> loginWithCredentials(
      String email,
      String password, {
        required void Function(String) onFailure,
        required void Function() onSuccess,
      }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);

    final result = await repo.signInWithEmailAndPassword(email, password);

    await result.fold(
          (error) async {
        state = AsyncValue.error(error, StackTrace.current);
        onFailure(error);
      },
          (user) async {
        // Automatically check/provision store after successful login
        await _ensureStoreExists(user.uid);

        state = AsyncValue.data(user);
        onSuccess();
      },
    );
  }

  Future<void> executeLogoutSequence() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }
}