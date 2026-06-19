// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerRepository)
final sellerRepositoryProvider = SellerRepositoryProvider._();

final class SellerRepositoryProvider
    extends
        $FunctionalProvider<
          SellerRepository,
          SellerRepository,
          SellerRepository
        >
    with $Provider<SellerRepository> {
  SellerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SellerRepository create(Ref ref) {
    return sellerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerRepository>(value),
    );
  }
}

String _$sellerRepositoryHash() => r'f6fa6a13cd3369a9d79acf84b7340617c8ec4e70';

@ProviderFor(SellerController)
final sellerControllerProvider = SellerControllerProvider._();

final class SellerControllerProvider
    extends $AsyncNotifierProvider<SellerController, StoreProfile?> {
  SellerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerControllerHash();

  @$internal
  @override
  SellerController create() => SellerController();
}

String _$sellerControllerHash() => r'dfdae08d1f86f3f30d7207fd38cedb89dffbe752';

abstract class _$SellerController extends $AsyncNotifier<StoreProfile?> {
  FutureOr<StoreProfile?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StoreProfile?>, StoreProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StoreProfile?>, StoreProfile?>,
              AsyncValue<StoreProfile?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
