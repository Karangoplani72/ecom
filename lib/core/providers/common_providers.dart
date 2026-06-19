import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'common_providers.g.dart';

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// The single source of truth for Firebase Auth's authentication state.
/// Backed directly by [FirebaseAuth.authStateChanges], so it updates
/// immediately on sign-in/sign-out — including the very first emission,
/// when Firebase resolves whatever session was persisted on disk.
///
/// Until that first emission arrives this provider is in its loading
/// state (`AsyncLoading`). Callers that need to tell "still resolving"
/// apart from "definitely signed out" should watch this provider
/// directly instead of [currentUserIdProvider], which collapses both
/// cases to `null`.
@riverpod
Stream<User?> firebaseAuthState(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// The current Firebase Auth user id, derived from
/// [firebaseAuthStateProvider]. Returns null both while the auth state is
/// still loading AND when the user is signed out — screens that must not
/// flash a "guest" UI during startup should watch
/// [firebaseAuthStateProvider] directly rather than relying on this.
@riverpod
String? currentUserId(Ref ref) {
  return ref.watch(firebaseAuthStateProvider).value?.uid;
}
