// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_finances_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerFinanceRepository)
final sellerFinanceRepositoryProvider = SellerFinanceRepositoryProvider._();

final class SellerFinanceRepositoryProvider
    extends
        $FunctionalProvider<
          SellerFinanceRepository,
          SellerFinanceRepository,
          SellerFinanceRepository
        >
    with $Provider<SellerFinanceRepository> {
  SellerFinanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerFinanceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerFinanceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerFinanceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerFinanceRepository create(Ref ref) {
    return sellerFinanceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerFinanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerFinanceRepository>(value),
    );
  }
}

String _$sellerFinanceRepositoryHash() =>
    r'4567bf459dd667a0d2152ed7a26f2499edba63c3';

@ProviderFor(merchantWallet)
final merchantWalletProvider = MerchantWalletProvider._();

final class MerchantWalletProvider
    extends
        $FunctionalProvider<
          AsyncValue<MerchantWallet>,
          MerchantWallet,
          FutureOr<MerchantWallet>
        >
    with $FutureModifier<MerchantWallet>, $FutureProvider<MerchantWallet> {
  MerchantWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'merchantWalletProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$merchantWalletHash();

  @$internal
  @override
  $FutureProviderElement<MerchantWallet> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MerchantWallet> create(Ref ref) {
    return merchantWallet(ref);
  }
}

String _$merchantWalletHash() => r'58a32536254bd493797bd7633bf9e7acc709e7a4';

@ProviderFor(SellerFinancesController)
final sellerFinancesControllerProvider = SellerFinancesControllerProvider._();

final class SellerFinancesControllerProvider
    extends $AsyncNotifierProvider<SellerFinancesController, MerchantWallet> {
  SellerFinancesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerFinancesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerFinancesControllerHash();

  @$internal
  @override
  SellerFinancesController create() => SellerFinancesController();
}

String _$sellerFinancesControllerHash() =>
    r'6dd8594f8a302c9b9453349b3079f9fa69bf36c1';

abstract class _$SellerFinancesController
    extends $AsyncNotifier<MerchantWallet> {
  FutureOr<MerchantWallet> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MerchantWallet>, MerchantWallet>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MerchantWallet>, MerchantWallet>,
              AsyncValue<MerchantWallet>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
