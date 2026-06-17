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
    r'e5c9d5ff0c17cfa1515fb586fa0df810ea707d2d';

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

String _$sellerProductsHash() => r'c8276cbc589c12a3d26d0ea4405a3c4eb4462afc';

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
    r'4eafb438f0e6ee1f5f729271d0288046ea2d5a38';

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
