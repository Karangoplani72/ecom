// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current user's [StaffPermissions] as a real-time stream.
///
/// - Sellers (store owners) always get [StaffPermissions.all()].
/// - Store managers get permissions read from Firestore in real-time,
///   so any changes by the seller are reflected instantly.

@ProviderFor(staffPermissions)
final staffPermissionsProvider = StaffPermissionsProvider._();

/// Provides the current user's [StaffPermissions] as a real-time stream.
///
/// - Sellers (store owners) always get [StaffPermissions.all()].
/// - Store managers get permissions read from Firestore in real-time,
///   so any changes by the seller are reflected instantly.

final class StaffPermissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffPermissions>,
          StaffPermissions,
          Stream<StaffPermissions>
        >
    with $FutureModifier<StaffPermissions>, $StreamProvider<StaffPermissions> {
  /// Provides the current user's [StaffPermissions] as a real-time stream.
  ///
  /// - Sellers (store owners) always get [StaffPermissions.all()].
  /// - Store managers get permissions read from Firestore in real-time,
  ///   so any changes by the seller are reflected instantly.
  StaffPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffPermissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffPermissionsHash();

  @$internal
  @override
  $StreamProviderElement<StaffPermissions> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StaffPermissions> create(Ref ref) {
    return staffPermissions(ref);
  }
}

String _$staffPermissionsHash() => r'19bc53cd781dac06c466f354f352bc3f347c471c';
