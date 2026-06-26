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

String _$adminRepositoryHash() => r'2d483e142c561be619420ef440448d9a7762f499';

@ProviderFor(adminDashboardMetrics)
final adminDashboardMetricsProvider = AdminDashboardMetricsProvider._();

final class AdminDashboardMetricsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminDashboardMetrics>,
          AdminDashboardMetrics,
          Stream<AdminDashboardMetrics>
        >
    with
        $FutureModifier<AdminDashboardMetrics>,
        $StreamProvider<AdminDashboardMetrics> {
  AdminDashboardMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminDashboardMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminDashboardMetricsHash();

  @$internal
  @override
  $StreamProviderElement<AdminDashboardMetrics> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AdminDashboardMetrics> create(Ref ref) {
    return adminDashboardMetrics(ref);
  }
}

String _$adminDashboardMetricsHash() =>
    r'3cff45ed6ec680e5eb2c9e2831d4f46dcbeb2f19';

@ProviderFor(pendingSellerApplications)
final pendingSellerApplicationsProvider = PendingSellerApplicationsProvider._();

final class PendingSellerApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerApplication>>,
          List<SellerApplication>,
          Stream<List<SellerApplication>>
        >
    with
        $FutureModifier<List<SellerApplication>>,
        $StreamProvider<List<SellerApplication>> {
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
  $StreamProviderElement<List<SellerApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SellerApplication>> create(Ref ref) {
    return pendingSellerApplications(ref);
  }
}

String _$pendingSellerApplicationsHash() =>
    r'6027b8d6f3bf839b836134bca02c8ebd4502cc0b';

@ProviderFor(adminAllStores)
final adminAllStoresProvider = AdminAllStoresProvider._();

final class AdminAllStoresProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StoreProfile>>,
          List<StoreProfile>,
          Stream<List<StoreProfile>>
        >
    with
        $FutureModifier<List<StoreProfile>>,
        $StreamProvider<List<StoreProfile>> {
  AdminAllStoresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAllStoresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAllStoresHash();

  @$internal
  @override
  $StreamProviderElement<List<StoreProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StoreProfile>> create(Ref ref) {
    return adminAllStores(ref);
  }
}

String _$adminAllStoresHash() => r'837f63563d4f7735a9996ecaadba986064663dc3';

@ProviderFor(adminAllUsers)
final adminAllUsersProvider = AdminAllUsersProvider._();

final class AdminAllUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminUser>>,
          List<AdminUser>,
          Stream<List<AdminUser>>
        >
    with $FutureModifier<List<AdminUser>>, $StreamProvider<List<AdminUser>> {
  AdminAllUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAllUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAllUsersHash();

  @$internal
  @override
  $StreamProviderElement<List<AdminUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AdminUser>> create(Ref ref) {
    return adminAllUsers(ref);
  }
}

String _$adminAllUsersHash() => r'ed3e13022ba2bf1724b19e0294e57c66140cc467';

@ProviderFor(adminAllDisputes)
final adminAllDisputesProvider = AdminAllDisputesProvider._();

final class AdminAllDisputesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DisputeTicket>>,
          List<DisputeTicket>,
          Stream<List<DisputeTicket>>
        >
    with
        $FutureModifier<List<DisputeTicket>>,
        $StreamProvider<List<DisputeTicket>> {
  AdminAllDisputesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAllDisputesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAllDisputesHash();

  @$internal
  @override
  $StreamProviderElement<List<DisputeTicket>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DisputeTicket>> create(Ref ref) {
    return adminAllDisputes(ref);
  }
}

String _$adminAllDisputesHash() => r'93670f143e6c6b255091cfc88625dad9db53020c';

@ProviderFor(adminAuditLogs)
final adminAuditLogsProvider = AdminAuditLogsProvider._();

final class AdminAuditLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditLog>>,
          List<AuditLog>,
          Stream<List<AuditLog>>
        >
    with $FutureModifier<List<AuditLog>>, $StreamProvider<List<AuditLog>> {
  AdminAuditLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAuditLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAuditLogsHash();

  @$internal
  @override
  $StreamProviderElement<List<AuditLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AuditLog>> create(Ref ref) {
    return adminAuditLogs(ref);
  }
}

String _$adminAuditLogsHash() => r'd0eae3685d083ea60df204ec7cf75f7f2969d324';

@ProviderFor(AdminController)
final adminControllerProvider = AdminControllerProvider._();

final class AdminControllerProvider
    extends $AsyncNotifierProvider<AdminController, void> {
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

String _$adminControllerHash() => r'327c9c08215464e608704b25c962d2b3b82659a4';

abstract class _$AdminController extends $AsyncNotifier<void> {
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
