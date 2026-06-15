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

String _$sellerControllerHash() => r'2e657e5d7a692b06cacad0299e3f2a7c717421c9';

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
