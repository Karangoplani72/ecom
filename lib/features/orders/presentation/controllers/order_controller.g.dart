// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderRepository)
final orderRepositoryProvider = OrderRepositoryProvider._();

final class OrderRepositoryProvider
    extends
        $FunctionalProvider<OrderRepository, OrderRepository, OrderRepository>
    with $Provider<OrderRepository> {
  OrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrderRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderRepository create(Ref ref) {
    return orderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderRepository>(value),
    );
  }
}

String _$orderRepositoryHash() => r'5028a55b764795f192591dc1a51fad11e4430313';

@ProviderFor(buyerOrders)
final buyerOrdersProvider = BuyerOrdersProvider._();

final class BuyerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppOrder>>,
          List<AppOrder>,
          Stream<List<AppOrder>>
        >
    with $FutureModifier<List<AppOrder>>, $StreamProvider<List<AppOrder>> {
  BuyerOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buyerOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buyerOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<AppOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppOrder>> create(Ref ref) {
    return buyerOrders(ref);
  }
}

String _$buyerOrdersHash() => r'a2c78fcdaf6800983c2af4ce3444ab878b35e744';

@ProviderFor(sellerOrders)
final sellerOrdersProvider = SellerOrdersProvider._();

final class SellerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppOrder>>,
          List<AppOrder>,
          Stream<List<AppOrder>>
        >
    with $FutureModifier<List<AppOrder>>, $StreamProvider<List<AppOrder>> {
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
  $StreamProviderElement<List<AppOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppOrder>> create(Ref ref) {
    return sellerOrders(ref);
  }
}

String _$sellerOrdersHash() => r'ce7266dc2869862202094e1ae2dbba9e087c8fc2';

@ProviderFor(OrderController)
final orderControllerProvider = OrderControllerProvider._();

final class OrderControllerProvider
    extends $AsyncNotifierProvider<OrderController, void> {
  OrderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderControllerHash();

  @$internal
  @override
  OrderController create() => OrderController();
}

String _$orderControllerHash() => r'ff1a58c359f4c3fcc18597c0b6d77538bf9db9a4';

abstract class _$OrderController extends $AsyncNotifier<void> {
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
