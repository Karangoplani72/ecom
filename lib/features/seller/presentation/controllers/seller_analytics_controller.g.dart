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

String _$sellerAnalyticsHash() => r'c1770ef290a40d85ad2a834eff39e6c42d8420a0';
