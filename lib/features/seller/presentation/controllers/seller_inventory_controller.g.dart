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

@ProviderFor(_firebaseFirestoreProvider)
final _firebaseFirestoreProviderProvider =
    _FirebaseFirestoreProviderProvider._();

final class _FirebaseFirestoreProviderProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  _FirebaseFirestoreProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_firebaseFirestoreProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_firebaseFirestoreProviderHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return _firebaseFirestoreProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$_firebaseFirestoreProviderHash() =>
    r'913e8b9665e655055ddbe3bd3baeeef3b77fe01a';

@ProviderFor(currentSellerId)
final currentSellerIdProvider = CurrentSellerIdProvider._();

final class CurrentSellerIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  CurrentSellerIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSellerIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSellerIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return currentSellerId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$currentSellerIdHash() => r'2a56907f530afafdbcf85ab10231be86bad2598a';

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

String _$sellerProductsHash() => r'edb621b6152749e1bba6834ec2dcec11d598ff2d';

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
    r'12ac4366d12f167c9cec4644b79b86985a8882e0';

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
