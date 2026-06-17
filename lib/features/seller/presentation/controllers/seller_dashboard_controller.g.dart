// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerDashboardRepository)
final sellerDashboardRepositoryProvider = SellerDashboardRepositoryProvider._();

final class SellerDashboardRepositoryProvider
    extends
        $FunctionalProvider<
          SellerDashboardRepository,
          SellerDashboardRepository,
          SellerDashboardRepository
        >
    with $Provider<SellerDashboardRepository> {
  SellerDashboardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerDashboardRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerDashboardRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerDashboardRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerDashboardRepository create(Ref ref) {
    return sellerDashboardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerDashboardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerDashboardRepository>(value),
    );
  }
}

String _$sellerDashboardRepositoryHash() =>
    r'e84797ea6bc8a6cd13b91fa16149876d1a8485cc';

@ProviderFor(sellerDashboard)
final sellerDashboardProvider = SellerDashboardProvider._();

final class SellerDashboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerDashboardData>,
          SellerDashboardData,
          FutureOr<SellerDashboardData>
        >
    with
        $FutureModifier<SellerDashboardData>,
        $FutureProvider<SellerDashboardData> {
  SellerDashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerDashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerDashboardHash();

  @$internal
  @override
  $FutureProviderElement<SellerDashboardData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerDashboardData> create(Ref ref) {
    return sellerDashboard(ref);
  }
}

String _$sellerDashboardHash() => r'839e1c739fbd85cd60d970681a085dd3c0d23df7';
