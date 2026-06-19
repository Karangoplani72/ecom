// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logistics_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(logisticsRepository)
final logisticsRepositoryProvider = LogisticsRepositoryProvider._();

final class LogisticsRepositoryProvider
    extends
        $FunctionalProvider<
          LogisticsRepository,
          LogisticsRepository,
          LogisticsRepository
        >
    with $Provider<LogisticsRepository> {
  LogisticsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logisticsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logisticsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LogisticsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LogisticsRepository create(Ref ref) {
    return logisticsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogisticsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogisticsRepository>(value),
    );
  }
}

String _$logisticsRepositoryHash() =>
    r'd43fac0279b4a69453b123afbf759d148b8aa4bd';

@ProviderFor(realTimeDispatchStream)
final realTimeDispatchStreamProvider = RealTimeDispatchStreamFamily._();

final class RealTimeDispatchStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeliveryAssignment>,
          DeliveryAssignment,
          Stream<DeliveryAssignment>
        >
    with
        $FutureModifier<DeliveryAssignment>,
        $StreamProvider<DeliveryAssignment> {
  RealTimeDispatchStreamProvider._({
    required RealTimeDispatchStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'realTimeDispatchStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realTimeDispatchStreamHash();

  @override
  String toString() {
    return r'realTimeDispatchStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DeliveryAssignment> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DeliveryAssignment> create(Ref ref) {
    final argument = this.argument as String;
    return realTimeDispatchStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RealTimeDispatchStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realTimeDispatchStreamHash() =>
    r'375f38b4f16fea01d5e97aba895c26d3b5e0132f';

final class RealTimeDispatchStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DeliveryAssignment>, String> {
  RealTimeDispatchStreamFamily._()
    : super(
        retry: null,
        name: r'realTimeDispatchStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RealTimeDispatchStreamProvider call(String orderId) =>
      RealTimeDispatchStreamProvider._(argument: orderId, from: this);

  @override
  String toString() => r'realTimeDispatchStreamProvider';
}

@ProviderFor(LogisticsController)
final logisticsControllerProvider = LogisticsControllerProvider._();

final class LogisticsControllerProvider
    extends $AsyncNotifierProvider<LogisticsController, void> {
  LogisticsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logisticsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logisticsControllerHash();

  @$internal
  @override
  LogisticsController create() => LogisticsController();
}

String _$logisticsControllerHash() =>
    r'35ef529a4eeeff057e70d628d380e24233eec00e';

abstract class _$LogisticsController extends $AsyncNotifier<void> {
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
