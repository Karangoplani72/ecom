// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_orders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider = FirebaseFirestoreProvider._();

final class FirebaseFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  FirebaseFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'963402713bf9b7cc1fb259d619d9b0184d4dcec1';

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

@ProviderFor(sellerOrderRepository)
final sellerOrderRepositoryProvider = SellerOrderRepositoryProvider._();

final class SellerOrderRepositoryProvider
    extends
        $FunctionalProvider<
          SellerOrderRepository,
          SellerOrderRepository,
          SellerOrderRepository
        >
    with $Provider<SellerOrderRepository> {
  SellerOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerOrderRepository create(Ref ref) {
    return sellerOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerOrderRepository>(value),
    );
  }
}

String _$sellerOrderRepositoryHash() =>
    r'7f0dc7be14b9bbfd56e3652f29b525727492c1c4';

@ProviderFor(sellerOrders)
final sellerOrdersProvider = SellerOrdersProvider._();

final class SellerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerOrder>>,
          List<SellerOrder>,
          Stream<List<SellerOrder>>
        >
    with
        $FutureModifier<List<SellerOrder>>,
        $StreamProvider<List<SellerOrder>> {
  SellerOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<SellerOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerOrder>> create(Ref ref) {
    return sellerOrders(ref);
  }
}

String _$sellerOrdersHash() => r'59b9bcc480987b2e952f176367263b5ff3ec40d9';

@ProviderFor(SellerOrdersController)
final sellerOrdersControllerProvider = SellerOrdersControllerProvider._();

final class SellerOrdersControllerProvider
    extends $AsyncNotifierProvider<SellerOrdersController, void> {
  SellerOrdersControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerOrdersControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerOrdersControllerHash();

  @$internal
  @override
  SellerOrdersController create() => SellerOrdersController();
}

String _$sellerOrdersControllerHash() =>
    r'192da3209a56f5bac0ffdd09e7316d292fc7ee39';

abstract class _$SellerOrdersController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
