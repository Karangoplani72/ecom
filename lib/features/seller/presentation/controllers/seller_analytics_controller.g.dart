// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_analytics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerAnalyticsRepository)
final sellerAnalyticsRepositoryProvider = SellerAnalyticsRepositoryProvider._();

final class SellerAnalyticsRepositoryProvider
    extends
        $FunctionalProvider<
          SellerAnalyticsRepository,
          SellerAnalyticsRepository,
          SellerAnalyticsRepository
        >
    with $Provider<SellerAnalyticsRepository> {
  SellerAnalyticsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerAnalyticsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerAnalyticsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerAnalyticsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerAnalyticsRepository create(Ref ref) {
    return sellerAnalyticsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerAnalyticsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerAnalyticsRepository>(value),
    );
  }
}

String _$sellerAnalyticsRepositoryHash() =>
    r'1f2672c86c55cd5c00c2efc4141a287a1f0da930';

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

@ProviderFor(sellerAnalytics)
final sellerAnalyticsProvider = SellerAnalyticsProvider._();

final class SellerAnalyticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerAnalytics>,
          SellerAnalytics,
          FutureOr<SellerAnalytics>
        >
    with $FutureModifier<SellerAnalytics>, $FutureProvider<SellerAnalytics> {
  SellerAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerAnalyticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerAnalyticsHash();

  @$internal
  @override
  $FutureProviderElement<SellerAnalytics> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerAnalytics> create(Ref ref) {
    return sellerAnalytics(ref);
  }
}

String _$sellerAnalyticsHash() => r'808b638e6c6977fd36f47c181dadbc1af52ee2a0';

@ProviderFor(SellerAnalyticsController)
final sellerAnalyticsControllerProvider = SellerAnalyticsControllerProvider._();

final class SellerAnalyticsControllerProvider
    extends $AsyncNotifierProvider<SellerAnalyticsController, SellerAnalytics> {
  SellerAnalyticsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerAnalyticsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerAnalyticsControllerHash();

  @$internal
  @override
  SellerAnalyticsController create() => SellerAnalyticsController();
}

String _$sellerAnalyticsControllerHash() =>
    r'1fc00253722086177366d41b9a9bddd1838bde10';

abstract class _$SellerAnalyticsController
    extends $AsyncNotifier<SellerAnalytics> {
  FutureOr<SellerAnalytics> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SellerAnalytics>, SellerAnalytics>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SellerAnalytics>, SellerAnalytics>,
              AsyncValue<SellerAnalytics>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
