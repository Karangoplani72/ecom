// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_staff_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SellerStaffController)
final sellerStaffControllerProvider = SellerStaffControllerProvider._();

final class SellerStaffControllerProvider
    extends $StreamNotifierProvider<SellerStaffController, SellerStaffState> {
  SellerStaffControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerStaffControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerStaffControllerHash();

  @$internal
  @override
  SellerStaffController create() => SellerStaffController();
}

String _$sellerStaffControllerHash() =>
    r'4521ac1a4438ba23a5639a05d73532ffddc0a18d';

abstract class _$SellerStaffController
    extends $StreamNotifier<SellerStaffState> {
  Stream<SellerStaffState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SellerStaffState>, SellerStaffState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SellerStaffState>, SellerStaffState>,
              AsyncValue<SellerStaffState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
