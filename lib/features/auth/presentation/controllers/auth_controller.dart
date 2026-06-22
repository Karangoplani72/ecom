import 'dart:async';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/auth/data/dtos/user_dto.dart';
import 'package:ecom/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/guest_cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/guest_wishlist_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<AppUser?> authStateSignaling(Ref ref) {
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .map((option) => option.fold(() => null, (user) => user));
}

/// Real-time Firestore listener on the signed-in user's own document.
/// Unlike [authStateSignalingProvider], which only fires on Firebase Auth
/// sign-in/sign-out events, this stays live across profile edits made
/// from any device or the admin panel.
///
/// This watches [firebaseAuthStateProvider] — the raw Firebase Auth
/// stream — rather than [currentUserIdProvider], so it rebuilds
/// immediately whenever auth state changes and so it can tell "auth is
/// still resolving" apart from "user is signed out": while auth state is
/// loading, this provider yields nothing and stays loading too, instead
/// of momentarily reporting `null` (which screens would otherwise read as
/// a definitive guest state).
@riverpod
Stream<AppUser?> currentUserProfile(Ref ref) async* {
  final authState = ref.watch(firebaseAuthStateProvider);

  if (authState.isLoading) {
    // Firebase Auth hasn't resolved the persisted session yet. Yield
    // nothing so this provider stays AsyncLoading; it will rebuild the
    // moment firebaseAuthStateProvider produces its first real value.
    return;
  }

  final firebaseUser = authState.value;
  if (firebaseUser == null) {
    yield null;
    return;
  }

  yield* ref
      .watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    try {
      return UserDto.fromFirestore(snapshot).toDomain();
    } catch (_) {
      return null;
    }
  });
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<AppUser?> build() {
    return null;
  }

  Future<void> _mergeGuestCart(String userId) async {
    final guestCartItems = ref.read(guestCartControllerProvider);
    if (guestCartItems.isNotEmpty) {
      final cartRepo = ref.read(cartRepositoryProvider);
      for (final item in guestCartItems) {
        await cartRepo.addCartItem(userId: userId, item: item);
      }
      ref.read(guestCartControllerProvider.notifier).clearCart();
    }
  }

  Future<void> _mergeGuestWishlist(String userId) async {
    final guestWishlistItems = ref.read(guestWishlistControllerProvider);
    if (guestWishlistItems.isNotEmpty) {
      final wishlistRepo = ref.read(wishlistRepositoryProvider);
      for (final item in guestWishlistItems) {
        await wishlistRepo.addToWishlist(userId: userId, item: item);
      }
      ref.read(guestWishlistControllerProvider.notifier).clearWishlist();
    }
  }

  Future<void> loginWithCredentials(String email,
      String password, {
        required void Function(String) onFailure,
        required void Function() onSuccess,
      }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);

    final result = await repo.signInWithEmailAndPassword(email, password);

    await result.fold(
          (error) async {
        if (!ref.mounted) return;
        state = AsyncValue.error(error, StackTrace.current);
        if (!ref.mounted) return;
        onFailure(error);
      },
          (user) async {
        if (!ref.mounted) return;
        state = AsyncValue.data(user);

        await _mergeGuestCart(user.uid);
        await _mergeGuestWishlist(user.uid);

        // Give GoRouter time to receive the auth stream update
        await Future.delayed(const Duration(milliseconds: 300));

        if (!ref.mounted) return;
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
          (user) async {
        state = AsyncData(user);
        
        await _mergeGuestCart(user.uid);
        await _mergeGuestWishlist(user.uid);
        
        onSuccess();
      },
    );
  }

  /// Updates the signed-in user's profile fields in Firestore.
  /// Only display name and phone number are user-editable.
  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    required void Function(String) onFailure,
  }) async {
    // This notifier's own `state` is only ever set by an explicit
    // login()/register() call in *this* app session, so it's null for an
    // already-signed-in user who launched straight into the app on a
    // persisted Firebase session. currentUserProfileProvider is the real
    // source of truth — fall back to it before declaring "not signed in".
    final current = ref
        .read(currentUserProfileProvider)
        .value ?? state.value;
    if (current == null) {
      onFailure('You must be signed in to update your profile.');
      return false;
    }

    final updates = <String, dynamic>{};
    if (displayName != null && displayName
        .trim()
        .isNotEmpty) {
      updates['displayName'] = displayName.trim();
    }
    if (phoneNumber != null) {
      updates['phoneNumber'] = phoneNumber.trim();
    }

    if (updates.isEmpty) return true;

    final result = await ref
        .read(authRepositoryProvider)
        .updateUserProfile(current.uid, updates);

    return result.fold(
          (error) {
        onFailure(error);
        return false;
      },
          (_) {
        // Optimistic update; currentUserProfileProvider's live Firestore
        // listener will also converge to the true server state.
        state = AsyncData(
          current.copyWith(
            displayName:
            updates['displayName'] as String? ?? current.displayName,
            phoneNumber: updates.containsKey('phoneNumber')
                ? (updates['phoneNumber'] as String).isEmpty
                ? null
                : updates['phoneNumber'] as String
                : current.phoneNumber,
          ),
        );
        return true;
      },
    );
  }

  /// Sends a password-reset email to the signed-in user's address.
  Future<bool> sendPasswordReset({
    required void Function(String) onFailure,
  }) async {
    // Same fallback as updateProfile — don't trust only this notifier's
    // own `state`, since it's never populated for a persisted session
    // that didn't go through loginWithCredentials in this app run.
    final email =
        ref
            .read(currentUserProfileProvider)
            .value
            ?.email ?? state.value?.email;
    if (email == null) {
      onFailure('No account email found.');
      return false;
    }

    final result = await ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email);

    return result.fold((error) {
      onFailure(error);
      return false;
    }, (_) => true);
  }
}