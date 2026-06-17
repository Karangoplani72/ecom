// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_orders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerOrderRepository)
final sellerOrderRepositoryProvider = SellerOrderRepositoryProvider._();

final class SellerOrderRepositoryProvider
    extends
        $FunctionalProvider<
          SellerOrderRepository,
          SellerOrderRepository,
          SellerOrderRepository
        >
    with $Provider<SellerOrderRepository> {
  SellerOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerOrderRepository create(Ref ref) {
    return sellerOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerOrderRepository>(value),
    );
  }
}

String _$sellerOrderRepositoryHash() =>
    r'7932919640505c35826cd2ea112e31a4a75e7c4a';

@ProviderFor(sellerOrders)
final sellerOrdersProvider = SellerOrdersProvider._();

final class SellerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerOrder>>,
          List<SellerOrder>,
          Stream<List<SellerOrder>>
        >
    with
        $FutureModifier<List<SellerOrder>>,
        $StreamProvider<List<SellerOrder>> {
  SellerOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<SellerOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerOrder>> create(Ref ref) {
    return sellerOrders(ref);
  }
}

String _$sellerOrdersHash() => r'6bb8c5d396d1cc598fb34afd7401baad4117ea75';

@ProviderFor(SellerOrdersController)
final sellerOrdersControllerProvider = SellerOrdersControllerProvider._();

final class SellerOrdersControllerProvider
    extends $AsyncNotifierProvider<SellerOrdersController, void> {
  SellerOrdersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrdersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrdersControllerHash();

  @$internal
  @override
  SellerOrdersController create() => SellerOrdersController();
}

String _$sellerOrdersControllerHash() =>
    r'44874647c4dc15a97da90d76fbd1d36a18ad6b1a';

abstract class _$SellerOrdersController extends $AsyncNotifier<void> {
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
