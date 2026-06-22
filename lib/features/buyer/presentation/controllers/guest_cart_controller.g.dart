// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_cart_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GuestCartController)
final guestCartControllerProvider = GuestCartControllerProvider._();

final class GuestCartControllerProvider
    extends $NotifierProvider<GuestCartController, List<CartItem>> {
  GuestCartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestCartControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestCartControllerHash();

  @$internal
  @override
  GuestCartController create() => GuestCartController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CartItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CartItem>>(value),
    );
  }
}

String _$guestCartControllerHash() =>
    r'68c7812db4fe668df35d697f4a62d102ca95855e';

abstract class _$GuestCartController extends $Notifier<List<CartItem>> {
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
