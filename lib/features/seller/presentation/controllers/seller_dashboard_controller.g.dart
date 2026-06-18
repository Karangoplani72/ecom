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

@ProviderFor(sellerDashboard)
final sellerDashboardProvider = SellerDashboardProvider._();

final class SellerDashboardProvider
    extends $FunctionalProvider<AsyncValue<Object>, Object, FutureOr<Object>>
    with $FutureModifier<Object>, $FutureProvider<Object> {
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
  $FutureProviderElement<Object> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Object> create(Ref ref) {
    return sellerDashboard(ref);
  }
}

String _$sellerDashboardHash() => r'15c09d4b08005a20a98d5fd4f2d7f0af4cc4a846';

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
    r'ab374cc8c8ffcd9f40773c5992656f952d651f97';

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
