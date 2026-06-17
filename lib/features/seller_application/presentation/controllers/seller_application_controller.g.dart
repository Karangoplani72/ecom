// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sellerApplicationRepository)
final sellerApplicationRepositoryProvider =
    SellerApplicationRepositoryProvider._();

final class SellerApplicationRepositoryProvider
    extends
        $FunctionalProvider<
          SellerApplicationRepository,
          SellerApplicationRepository,
          SellerApplicationRepository
        >
    with $Provider<SellerApplicationRepository> {
  SellerApplicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerApplicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerApplicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerApplicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SellerApplicationRepository create(Ref ref) {
    return sellerApplicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerApplicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerApplicationRepository>(value),
    );
  }
}

String _$sellerApplicationRepositoryHash() =>
    r'1cc696a3d6a15e0c701c10998f5f9e341b34817a';

@ProviderFor(SellerApplicationController)
final sellerApplicationControllerProvider =
    SellerApplicationControllerProvider._();

final class SellerApplicationControllerProvider
    extends $AsyncNotifierProvider<SellerApplicationController, void> {
  SellerApplicationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerApplicationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerApplicationControllerHash();

  @$internal
  @override
  SellerApplicationController create() => SellerApplicationController();
}

String _$sellerApplicationControllerHash() =>
    r'f7921110824373793ddd48b0e983e74aedd54518';

abstract class _$SellerApplicationController extends $AsyncNotifier<void> {
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
