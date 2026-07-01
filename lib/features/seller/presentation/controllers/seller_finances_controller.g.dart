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

String _$merchantWalletHash() => r'86e0d751ee39984060dc101804708851097748dc';

@ProviderFor(sellerBankAccount)
final sellerBankAccountProvider = SellerBankAccountProvider._();

final class SellerBankAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  SellerBankAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerBankAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerBankAccountHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    return sellerBankAccount(ref);
  }
}

String _$sellerBankAccountHash() => r'd381b6914a72dc0c1f209d5936601780e6e3e23c';

@ProviderFor(sellerTransactions)
final sellerTransactionsProvider = SellerTransactionsProvider._();

final class SellerTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerTransaction>>,
          List<SellerTransaction>,
          FutureOr<List<SellerTransaction>>
        >
    with
        $FutureModifier<List<SellerTransaction>>,
        $FutureProvider<List<SellerTransaction>> {
  SellerTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<SellerTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SellerTransaction>> create(Ref ref) {
    return sellerTransactions(ref);
  }
}

String _$sellerTransactionsHash() =>
    r'62039393106ad243109588515d3f2be0d6c45377';

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
    r'6dad540de669ba53b5934bf5c6c9671de03029aa';

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
