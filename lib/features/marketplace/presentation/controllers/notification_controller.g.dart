// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userNotifications)
final userNotificationsProvider = UserNotificationsProvider._();

final class UserNotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          Stream<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $StreamProvider<List<AppNotification>> {
  UserNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userNotificationsHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return userNotifications(ref);
  }
}

String _$userNotificationsHash() => r'8df91429450de53b6a65c37121464dd384fbfd57';

@ProviderFor(NotificationController)
final notificationControllerProvider = NotificationControllerProvider._();

final class NotificationControllerProvider
    extends $AsyncNotifierProvider<NotificationController, void> {
  NotificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationControllerHash();

  @$internal
  @override
  NotificationController create() => NotificationController();
}

String _$notificationControllerHash() =>
    r'f63e2323fa612a4cb76abf48f5adfc1c56e7b206';

abstract class _$NotificationController extends $AsyncNotifier<void> {
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
