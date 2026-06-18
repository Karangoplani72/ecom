// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'90dd63123cf72f50c34c19ab6e36f8e68a6315d1';

@ProviderFor(pendingSellerApplications)
final pendingSellerApplicationsProvider = PendingSellerApplicationsProvider._();

final class PendingSellerApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerApplication>>,
          List<SellerApplication>,
          FutureOr<List<SellerApplication>>
        >
    with
        $FutureModifier<List<SellerApplication>>,
        $FutureProvider<List<SellerApplication>> {
  PendingSellerApplicationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSellerApplicationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSellerApplicationsHash();

  @$internal
  @override
  $FutureProviderElement<List<SellerApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SellerApplication>> create(Ref ref) {
    return pendingSellerApplications(ref);
  }
}

String _$pendingSellerApplicationsHash() =>
    r'e19649ce6f82db9e811eb8efe8d5914f987b61c8';

@ProviderFor(AdminController)
final adminControllerProvider = AdminControllerProvider._();

final class AdminControllerProvider
    extends $AsyncNotifierProvider<AdminController, List<DisputeTicket>> {
  AdminControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminControllerHash();

  @$internal
  @override
  AdminController create() => AdminController();
}

String _$adminControllerHash() => r'b96f4f54494a3d65031236e47c9e1af63d6e40b0';

abstract class _$AdminController extends $AsyncNotifier<List<DisputeTicket>> {
  FutureOr<List<DisputeTicket>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DisputeTicket>>, List<DisputeTicket>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DisputeTicket>>, List<DisputeTicket>>,
              AsyncValue<List<DisputeTicket>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
