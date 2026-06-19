// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(communicationRepository)
final communicationRepositoryProvider = CommunicationRepositoryProvider._();

final class CommunicationRepositoryProvider
    extends
        $FunctionalProvider<
          CommunicationRepository,
          CommunicationRepository,
          CommunicationRepository
        >
    with $Provider<CommunicationRepository> {
  CommunicationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'communicationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communicationRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommunicationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CommunicationRepository create(Ref ref) {
    return communicationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunicationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunicationRepository>(value),
    );
  }
}

String _$communicationRepositoryHash() =>
    r'42d9dfc77f6c9a849b56b6d601125ac80ff0a0d4';

@ProviderFor(liveMessageStream)
final liveMessageStreamProvider = LiveMessageStreamFamily._();

final class LiveMessageStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  LiveMessageStreamProvider._({
    required LiveMessageStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveMessageStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveMessageStreamHash();

  @override
  String toString() {
    return r'liveMessageStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return liveMessageStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveMessageStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveMessageStreamHash() => r'6f616d40278a08756c1a7952b74fdf197ff8b75d';

final class LiveMessageStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  LiveMessageStreamFamily._()
    : super(
        retry: null,
        name: r'liveMessageStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LiveMessageStreamProvider call(String roomId) =>
      LiveMessageStreamProvider._(argument: roomId, from: this);

  @override
  String toString() => r'liveMessageStreamProvider';
}

@ProviderFor(CommunicationController)
final communicationControllerProvider = CommunicationControllerProvider._();

final class CommunicationControllerProvider
    extends $AsyncNotifierProvider<CommunicationController, void> {
  CommunicationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'communicationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communicationControllerHash();

  @$internal
  @override
  CommunicationController create() => CommunicationController();
}

String _$communicationControllerHash() =>
    r'20152f3998e090b0e890b0c39e5e189e93ecbf64';

abstract class _$CommunicationController extends $AsyncNotifier<void> {
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
