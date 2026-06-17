// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$cartControllerHash() => r'63f4b7e046828c748ae36a6830e5ed1b11dc5de6';

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
