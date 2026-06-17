import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .map((option) => option.fold(() => null, (user) => user));
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<AppUser?> build() {
    return null;
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
        if (!ref.mounted) {
          return;
        }

        state = AsyncValue.error(error, StackTrace.current);

        if (!ref.mounted) {
          return;
        }

        onFailure(error);
      },
      (user) async {
        await _ensureStoreExists(user.uid);

        if (!ref.mounted) {
          return;
        }

        state = AsyncValue.data(user);

        // Give GoRouter time to receive the auth stream update
        await Future.delayed(const Duration(milliseconds: 300));

        if (!ref.mounted) {
          return;
        }

        onSuccess();
      },
    );
  }

  Future<void> executeLogoutSequence() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> registerWithCredentials({
    required String fullName,
    required String email,
    required String password,
    required Function(String) onFailure,
    required Function() onSuccess,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);

    final result = await repo.signUpWithEmailAndPassword(
      email,
      password,
      fullName,
    );

    result.fold(
      (failure) {
        state = AsyncError(failure, StackTrace.current);

        onFailure(failure);
      },
      (user) {
        state = AsyncData(user);
        onSuccess();
      },
    );
  }
}
