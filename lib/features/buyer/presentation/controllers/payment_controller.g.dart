// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentRepository)
final paymentRepositoryProvider = PaymentRepositoryProvider._();

final class PaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentRepository,
          PaymentRepository,
          PaymentRepository
        >
    with $Provider<PaymentRepository> {
  PaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentRepository create(Ref ref) {
    return paymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentRepository>(value),
    );
  }
}

String _$paymentRepositoryHash() => r'edbfb79074587380d4cffb2b50ed178c94b57a0d';

@ProviderFor(PaymentController)
final paymentControllerProvider = PaymentControllerProvider._();

final class PaymentControllerProvider
    extends $AsyncNotifierProvider<PaymentController, PaymentTransaction?> {
  PaymentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentControllerHash();

  @$internal
  @override
  PaymentController create() => PaymentController();
}

String _$paymentControllerHash() => r'a9f65a19ef313bd7628caf1424fbcb4f3ec3b79a';

abstract class _$PaymentController extends $AsyncNotifier<PaymentTransaction?> {
  FutureOr<PaymentTransaction?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PaymentTransaction?>, PaymentTransaction?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PaymentTransaction?>, PaymentTransaction?>,
              AsyncValue<PaymentTransaction?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
