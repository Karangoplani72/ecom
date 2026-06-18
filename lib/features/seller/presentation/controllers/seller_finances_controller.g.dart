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
    r'ea114323aa4d23681fa70da8437e704ece80bc3b';

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

String _$merchantWalletHash() => r'26837831fb5c052046c07e3b236fe8349026f508';

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
    r'cc1ff870815b4182e58f1b0305e5ae493243ad5a';

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
