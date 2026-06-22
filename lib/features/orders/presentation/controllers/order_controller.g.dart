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

String _$orderRepositoryHash() => r'c39db9b25d0c34524fdb1f748ce6854d54a796d0';

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

String _$buyerOrdersHash() => r'459b14f31281ced2b0a4dd5a9e38d8418f64e200';

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

String _$sellerOrdersHash() => r'4e857b2b2ce509babd90436b5918de990d95c1bc';

@ProviderFor(orderById)
final orderByIdProvider = OrderByIdFamily._();

final class OrderByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppOrder?>,
          AppOrder?,
          FutureOr<AppOrder?>
        >
    with $FutureModifier<AppOrder?>, $FutureProvider<AppOrder?> {
  OrderByIdProvider._({
    required OrderByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderByIdHash();

  @override
  String toString() {
    return r'orderByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AppOrder?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppOrder?> create(Ref ref) {
    final argument = this.argument as String;
    return orderById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderByIdHash() => r'95b6abc7730219038af7d0dfd10fdb0ce75a20e8';

final class OrderByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AppOrder?>, String> {
  OrderByIdFamily._()
    : super(
        retry: null,
        name: r'orderByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderByIdProvider call(String orderId) =>
      OrderByIdProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderByIdProvider';
}

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

String _$orderControllerHash() => r'de3b9a44611cce14fab25645b339c336741a3c93';

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
