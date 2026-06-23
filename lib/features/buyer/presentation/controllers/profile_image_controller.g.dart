// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_image_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'0323b7b9261b92497765aa810f6c8ba06019c22f';

@ProviderFor(ProfileImageController)
final profileImageControllerProvider = ProfileImageControllerProvider._();

final class ProfileImageControllerProvider
    extends $NotifierProvider<ProfileImageController, ProfileImageState> {
  ProfileImageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileImageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileImageControllerHash();

  @$internal
  @override
  ProfileImageController create() => ProfileImageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileImageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileImageState>(value),
    );
  }
}

String _$profileImageControllerHash() =>
    r'e9e4402b9e8ec174501bf22897243ae43493853e';

abstract class _$ProfileImageController extends $Notifier<ProfileImageState> {
  ProfileImageState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProfileImageState, ProfileImageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileImageState, ProfileImageState>,
              ProfileImageState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(optimisticUserPhoto)
final optimisticUserPhotoProvider = OptimisticUserPhotoProvider._();

final class OptimisticUserPhotoProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  OptimisticUserPhotoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'optimisticUserPhotoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$optimisticUserPhotoHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return optimisticUserPhoto(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$optimisticUserPhotoHash() =>
    r'960b413f0e9227771afec0ae42df09d7420ca5c0';

@ProviderFor(optimisticProfile)
final optimisticProfileProvider = OptimisticProfileProvider._();

final class OptimisticProfileProvider
    extends
        $FunctionalProvider<
          OptimisticProfile,
          OptimisticProfile,
          OptimisticProfile
        >
    with $Provider<OptimisticProfile> {
  OptimisticProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'optimisticProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$optimisticProfileHash();

  @$internal
  @override
  $ProviderElement<OptimisticProfile> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OptimisticProfile create(Ref ref) {
    return optimisticProfile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OptimisticProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OptimisticProfile>(value),
    );
  }
}

String _$optimisticProfileHash() => r'23bf796547ee948a54088825b1d404ddb2f7b4eb';
