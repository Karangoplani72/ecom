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
    r'4111ec6648b2dc9a6671cb2162ca27c73c6a8778';

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

String _$sellerAnalyticsHash() => r'85ee50ea45a7a7e032743069f53fc772e1b2c0d8';

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
    r'9c619f64cf1cb78c9886a89f710243a02c893012';

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
