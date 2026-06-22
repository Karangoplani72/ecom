// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider = FirebaseFirestoreProvider._();

final class FirebaseFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  FirebaseFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'963402713bf9b7cc1fb259d619d9b0184d4dcec1';

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          SharedPreferences,
          SharedPreferences,
          SharedPreferences
        >
    with $Provider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $ProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SharedPreferences create(Ref ref) {
    return sharedPreferences(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedPreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedPreferences>(value),
    );
  }
}

String _$sharedPreferencesHash() => r'e0d62a967dea277361f998f2b3253e0fa568eae4';

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'912368c3df3f72e4295bf7a8cda93b9c5749d923';

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

@ProviderFor(firebaseAuthState)
final firebaseAuthStateProvider = FirebaseAuthStateProvider._();

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

final class FirebaseAuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
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
  FirebaseAuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return firebaseAuthState(ref);
  }
}

String _$firebaseAuthStateHash() => r'4b30058f34c275203774ed4d832947e4861b7eea';

/// The current Firebase Auth user id, derived from
/// [firebaseAuthStateProvider]. Returns null both while the auth state is
/// still loading AND when the user is signed out — screens that must not
/// flash a "guest" UI during startup should watch
/// [firebaseAuthStateProvider] directly rather than relying on this.

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

/// The current Firebase Auth user id, derived from
/// [firebaseAuthStateProvider]. Returns null both while the auth state is
/// still loading AND when the user is signed out — screens that must not
/// flash a "guest" UI during startup should watch
/// [firebaseAuthStateProvider] directly rather than relying on this.

final class CurrentUserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The current Firebase Auth user id, derived from
  /// [firebaseAuthStateProvider]. Returns null both while the auth state is
  /// still loading AND when the user is signed out — screens that must not
  /// flash a "guest" UI during startup should watch
  /// [firebaseAuthStateProvider] directly rather than relying on this.
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentUserIdHash() => r'af2d91f73549ea3d20b88c6c6e5552fefec9819a';
