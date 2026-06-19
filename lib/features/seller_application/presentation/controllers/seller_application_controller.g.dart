// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerApplicationRepository)
final sellerApplicationRepositoryProvider =
    SellerApplicationRepositoryProvider._();

final class SellerApplicationRepositoryProvider
    extends
        $FunctionalProvider<
          SellerApplicationRepository,
          SellerApplicationRepository,
          SellerApplicationRepository
        >
    with $Provider<SellerApplicationRepository> {
  SellerApplicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerApplicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerApplicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerApplicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerApplicationRepository create(Ref ref) {
    return sellerApplicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerApplicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerApplicationRepository>(value),
    );
  }
}

String _$sellerApplicationRepositoryHash() =>
    r'b55d5b9ed9635b67afce3f89119f7944b3d2e4ad';

@ProviderFor(userSellerApplication)
final userSellerApplicationProvider = UserSellerApplicationProvider._();

final class UserSellerApplicationProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerApplication?>,
          SellerApplication?,
          FutureOr<SellerApplication?>
        >
    with
        $FutureModifier<SellerApplication?>,
        $FutureProvider<SellerApplication?> {
  UserSellerApplicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSellerApplicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSellerApplicationHash();

  @$internal
  @override
  $FutureProviderElement<SellerApplication?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerApplication?> create(Ref ref) {
    return userSellerApplication(ref);
  }
}

String _$userSellerApplicationHash() =>
    r'7be474a7f2cdb2bcfe85f56d17414c66eb2c8785';

@ProviderFor(SellerApplicationController)
final sellerApplicationControllerProvider =
    SellerApplicationControllerProvider._();

final class SellerApplicationControllerProvider
    extends $AsyncNotifierProvider<SellerApplicationController, void> {
  SellerApplicationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerApplicationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerApplicationControllerHash();

  @$internal
  @override
  SellerApplicationController create() => SellerApplicationController();
}

String _$sellerApplicationControllerHash() =>
    r'cb4a2580e20b9f8132b393e882914af0505fada3';

abstract class _$SellerApplicationController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
