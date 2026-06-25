// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_inventory_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerProductRepository)
final sellerProductRepositoryProvider = SellerProductRepositoryProvider._();

final class SellerProductRepositoryProvider
    extends
        $FunctionalProvider<
          SellerProductRepository,
          SellerProductRepository,
          SellerProductRepository
        >
    with $Provider<SellerProductRepository> {
  SellerProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerProductRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerProductRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerProductRepository create(Ref ref) {
    return sellerProductRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerProductRepository>(value),
    );
  }
}

String _$sellerProductRepositoryHash() =>
    r'f6b3675db79551b90c9c1c2a1c28c9913a1f8a20';

@ProviderFor(sellerProducts)
final sellerProductsProvider = SellerProductsProvider._();

final class SellerProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerProduct>>,
          List<SellerProduct>,
          Stream<List<SellerProduct>>
        >
    with
        $FutureModifier<List<SellerProduct>>,
        $StreamProvider<List<SellerProduct>> {
  SellerProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerProductsHash();

  @$internal
  @override
  $StreamProviderElement<List<SellerProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerProduct>> create(Ref ref) {
    return sellerProducts(ref);
  }
}

String _$sellerProductsHash() => r'3d16cd8210c92c42b9f71384d8ebce61e3b3dae7';

@ProviderFor(SellerInventoryController)
final sellerInventoryControllerProvider = SellerInventoryControllerProvider._();

final class SellerInventoryControllerProvider
    extends $AsyncNotifierProvider<SellerInventoryController, void> {
  SellerInventoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerInventoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerInventoryControllerHash();

  @$internal
  @override
  SellerInventoryController create() => SellerInventoryController();
}

String _$sellerInventoryControllerHash() =>
    r'a30c1f917c08d3e197fe9be818ae7357179c21f9';

abstract class _$SellerInventoryController extends $AsyncNotifier<void> {
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
