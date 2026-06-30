// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_name_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminNameResolver)
final adminNameResolverProvider = AdminNameResolverProvider._();

final class AdminNameResolverProvider
    extends $NotifierProvider<AdminNameResolver, void> {
  AdminNameResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNameResolverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminNameResolverHash();

  @$internal
  @override
  AdminNameResolver create() => AdminNameResolver();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$adminNameResolverHash() => r'ec55c287fb8c79ecbd1f88df6642fde586341589';

abstract class _$AdminNameResolver extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
