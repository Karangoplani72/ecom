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

@ProviderFor(chatRoomsStream)
final chatRoomsStreamProvider = ChatRoomsStreamFamily._();

final class ChatRoomsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatRoom>>,
          List<ChatRoom>,
          Stream<List<ChatRoom>>
        >
    with $FutureModifier<List<ChatRoom>>, $StreamProvider<List<ChatRoom>> {
  ChatRoomsStreamProvider._({
    required ChatRoomsStreamFamily super.from,
    required (String, {bool isStaff}) super.argument,
  }) : super(
         retry: null,
         name: r'chatRoomsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatRoomsStreamHash();

  @override
  String toString() {
    return r'chatRoomsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatRoom>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatRoom>> create(Ref ref) {
    final argument = this.argument as (String, {bool isStaff});
    return chatRoomsStream(ref, argument.$1, isStaff: argument.isStaff);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatRoomsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatRoomsStreamHash() => r'dd0c087bd529af306ca2fc4c769f775f4e29447a';

final class ChatRoomsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ChatRoom>>,
          (String, {bool isStaff})
        > {
  ChatRoomsStreamFamily._()
    : super(
        retry: null,
        name: r'chatRoomsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatRoomsStreamProvider call(String userId, {bool isStaff = false}) =>
      ChatRoomsStreamProvider._(
        argument: (userId, isStaff: isStaff),
        from: this,
      );

  @override
  String toString() => r'chatRoomsStreamProvider';
}

@ProviderFor(otherTypingStream)
final otherTypingStreamProvider = OtherTypingStreamFamily._();

final class OtherTypingStreamProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  OtherTypingStreamProvider._({
    required OtherTypingStreamFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'otherTypingStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$otherTypingStreamHash();

  @override
  String toString() {
    return r'otherTypingStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as (String, String);
    return otherTypingStream(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherTypingStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$otherTypingStreamHash() => r'6eeb885cdf7a6bce0799f30fffb7998818a07477';

final class OtherTypingStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, (String, String)> {
  OtherTypingStreamFamily._()
    : super(
        retry: null,
        name: r'otherTypingStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OtherTypingStreamProvider call(String chatId, String userId) =>
      OtherTypingStreamProvider._(argument: (chatId, userId), from: this);

  @override
  String toString() => r'otherTypingStreamProvider';
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
    r'797318612bf62bed0498e1119e4fa208e19ff2e3';

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
