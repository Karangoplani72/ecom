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
    r'b364e874fd29e558674fab1453880d650bc3687a';

@ProviderFor(SellerDashboardController)
final sellerDashboardControllerProvider = SellerDashboardControllerProvider._();

final class SellerDashboardControllerProvider
    extends
        $AsyncNotifierProvider<SellerDashboardController, SellerDashboardData> {
  SellerDashboardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerDashboardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerDashboardControllerHash();

  @$internal
  @override
  SellerDashboardController create() => SellerDashboardController();
}

String _$sellerDashboardControllerHash() =>
    r'8dce3a15eca9fa182f9958884a3fdb5cce3773b1';

abstract class _$SellerDashboardController
    extends $AsyncNotifier<SellerDashboardData> {
  FutureOr<SellerDashboardData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SellerDashboardData>, SellerDashboardData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SellerDashboardData>, SellerDashboardData>,
              AsyncValue<SellerDashboardData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
