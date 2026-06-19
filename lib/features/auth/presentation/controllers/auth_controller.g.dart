// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'6917f7befaa6f36499c6ec493d5c158835d6f138';

@ProviderFor(authStateSignaling)
final authStateSignalingProvider = AuthStateSignalingProvider._();

final class AuthStateSignalingProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  AuthStateSignalingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateSignalingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateSignalingHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authStateSignaling(ref);
  }
}

String _$authStateSignalingHash() =>
    r'c7561db6ea52550692deaff3fe9476f084b28ee6';

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

@ProviderFor(currentUserProfile)
final currentUserProfileProvider = CurrentUserProfileProvider._();

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

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
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
  CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'66ae0e5e75ea58fab91759ec807e0975be906d79';

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, AppUser?> {
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'ae05278b7783dbd5209af6abc31c3921259cd74e';

abstract class _$AuthController extends $AsyncNotifier<AppUser?> {
  FutureOr<AppUser?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppUser?>, AppUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppUser?>, AppUser?>,
              AsyncValue<AppUser?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
