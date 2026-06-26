// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guest_wishlist_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GuestWishlistController)
final guestWishlistControllerProvider = GuestWishlistControllerProvider._();

final class GuestWishlistControllerProvider
    extends $NotifierProvider<GuestWishlistController, List<CatalogItem>> {
  GuestWishlistControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guestWishlistControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guestWishlistControllerHash();

  @$internal
  @override
  GuestWishlistController create() => GuestWishlistController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CatalogItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CatalogItem>>(value),
    );
  }
}

String _$guestWishlistControllerHash() =>
    r'a8acb1d4e35c416bae1dbb23cdfa8a264f25fc7e';

abstract class _$GuestWishlistController extends $Notifier<List<CatalogItem>> {
  List<CatalogItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<CatalogItem>, List<CatalogItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CatalogItem>, List<CatalogItem>>,
              List<CatalogItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
