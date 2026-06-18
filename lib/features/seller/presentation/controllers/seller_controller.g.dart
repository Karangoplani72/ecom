// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerRepository)
final sellerRepositoryProvider = SellerRepositoryProvider._();

final class SellerRepositoryProvider
    extends
        $FunctionalProvider<
          SellerRepository,
          SellerRepository,
          SellerRepository
        >
    with $Provider<SellerRepository> {
  SellerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SellerRepository create(Ref ref) {
    return sellerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerRepository>(value),
    );
  }
}

String _$sellerRepositoryHash() => r'63d81d6b3a6d84be2c583f38d81691a53a12a000';

@ProviderFor(_currentSellerIdProvider)
final _currentSellerIdProviderProvider = _CurrentSellerIdProviderProvider._();

final class _CurrentSellerIdProviderProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  _CurrentSellerIdProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_currentSellerIdProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_currentSellerIdProviderHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return _currentSellerIdProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$_currentSellerIdProviderHash() =>
    r'653a6adb35fdb7e339918c92e3c3bdb948bdada7';

@ProviderFor(SellerController)
final sellerControllerProvider = SellerControllerProvider._();

final class SellerControllerProvider
    extends $AsyncNotifierProvider<SellerController, StoreProfile?> {
  SellerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerControllerHash();

  @$internal
  @override
  SellerController create() => SellerController();
}

String _$sellerControllerHash() => r'988a815fecf31a4ee36815fcbf23f038e4ae413d';

abstract class _$SellerController extends $AsyncNotifier<StoreProfile?> {
  FutureOr<StoreProfile?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StoreProfile?>, StoreProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StoreProfile?>, StoreProfile?>,
              AsyncValue<StoreProfile?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
