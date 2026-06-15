// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketplaceRepository)
final marketplaceRepositoryProvider = MarketplaceRepositoryProvider._();

final class MarketplaceRepositoryProvider
    extends
        $FunctionalProvider<
          MarketplaceRepository,
          MarketplaceRepository,
          MarketplaceRepository
        >
    with $Provider<MarketplaceRepository> {
  MarketplaceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketplaceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketplaceRepositoryHash();

  @$internal
  @override
  $ProviderElement<MarketplaceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketplaceRepository create(Ref ref) {
    return marketplaceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketplaceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketplaceRepository>(value),
    );
  }
}

String _$marketplaceRepositoryHash() =>
    r'a4222bc3bd1560ccf636069c2e10d42af2586702';

@ProviderFor(MarketplaceController)
final marketplaceControllerProvider = MarketplaceControllerProvider._();

final class MarketplaceControllerProvider
    extends $AsyncNotifierProvider<MarketplaceController, List<CatalogItem>> {
  MarketplaceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketplaceControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketplaceControllerHash();

  @$internal
  @override
  MarketplaceController create() => MarketplaceController();
}

String _$marketplaceControllerHash() =>
    r'01a28821a6f59f80e928297fbbd4614ea8cd113c';

abstract class _$MarketplaceController
    extends $AsyncNotifier<List<CatalogItem>> {
  FutureOr<List<CatalogItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CatalogItem>>, List<CatalogItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CatalogItem>>, List<CatalogItem>>,
              AsyncValue<List<CatalogItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
