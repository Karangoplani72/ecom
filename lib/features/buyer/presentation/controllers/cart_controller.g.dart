// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cartRepository)
final cartRepositoryProvider = CartRepositoryProvider._();

final class CartRepositoryProvider
    extends $FunctionalProvider<CartRepository, CartRepository, CartRepository>
    with $Provider<CartRepository> {
  CartRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartRepositoryHash();

  @$internal
  @override
  $ProviderElement<CartRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CartRepository create(Ref ref) {
    return cartRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartRepository>(value),
    );
  }
}

String _$cartRepositoryHash() => r'1637ea63ab43e7cebae15faa6dd20ea8b137d5b8';

@ProviderFor(AppliedCoupon)
final appliedCouponProvider = AppliedCouponProvider._();

final class AppliedCouponProvider
    extends $NotifierProvider<AppliedCoupon, Coupon?> {
  AppliedCouponProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appliedCouponProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appliedCouponHash();

  @$internal
  @override
  AppliedCoupon create() => AppliedCoupon();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Coupon? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Coupon?>(value),
    );
  }
}

String _$appliedCouponHash() => r'427e4ded30da82b9f34566bd3956b4260658b0a8';

abstract class _$AppliedCoupon extends $Notifier<Coupon?> {
  Coupon? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Coupon?, Coupon?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Coupon?, Coupon?>,
              Coupon?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(cartStream)
final cartStreamProvider = CartStreamProvider._();

final class CartStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CartItem>>,
          List<CartItem>,
          Stream<List<CartItem>>
        >
    with $FutureModifier<List<CartItem>>, $StreamProvider<List<CartItem>> {
  CartStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<CartItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CartItem>> create(Ref ref) {
    return cartStream(ref);
  }
}

String _$cartStreamHash() => r'48c78a7c32b0baaa46e1e16f7712b0cdd339b9b9';

@ProviderFor(CartController)
final cartControllerProvider = CartControllerProvider._();

final class CartControllerProvider
    extends $NotifierProvider<CartController, List<CartItem>> {
  CartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartControllerHash();

  @$internal
  @override
  CartController create() => CartController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CartItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CartItem>>(value),
    );
  }
}

String _$cartControllerHash() => r'bd730d4b3782c91a765c802701d1fb93bde0af19';

abstract class _$CartController extends $Notifier<List<CartItem>> {
  List<CartItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<CartItem>, List<CartItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CartItem>, List<CartItem>>,
              List<CartItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
