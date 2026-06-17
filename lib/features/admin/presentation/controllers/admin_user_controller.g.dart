// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminUserRepository)
final adminUserRepositoryProvider = AdminUserRepositoryProvider._();

final class AdminUserRepositoryProvider
    extends
        $FunctionalProvider<
          AdminUserRepository,
          AdminUserRepository,
          AdminUserRepository
        >
    with $Provider<AdminUserRepository> {
  AdminUserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUserRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUserRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminUserRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminUserRepository create(Ref ref) {
    return adminUserRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminUserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminUserRepository>(value),
    );
  }
}

String _$adminUserRepositoryHash() =>
    r'5a19ef4a43b1234f587db6de9a19121c7af3f8d9';

@ProviderFor(adminUsers)
final adminUsersProvider = AdminUsersProvider._();

final class AdminUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminUser>>,
          List<AdminUser>,
          Stream<List<AdminUser>>
        >
    with $FutureModifier<List<AdminUser>>, $StreamProvider<List<AdminUser>> {
  AdminUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUsersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUsersHash();

  @$internal
  @override
  $StreamProviderElement<List<AdminUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AdminUser>> create(Ref ref) {
    return adminUsers(ref);
  }
}

String _$adminUsersHash() => r'b746cb65da9a1463bb9e5ab9f1c7cf863032ce96';

@ProviderFor(AdminUserController)
final adminUserControllerProvider = AdminUserControllerProvider._();

final class AdminUserControllerProvider
    extends $AsyncNotifierProvider<AdminUserController, void> {
  AdminUserControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminUserControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminUserControllerHash();

  @$internal
  @override
  AdminUserController create() => AdminUserController();
}

String _$adminUserControllerHash() =>
    r'b86b73ae873daec2a8942f69a71ca9979c7800d1';

abstract class _$AdminUserController extends $AsyncNotifier<void> {
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
