// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_recognition_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SpeechRecognitionController)
final speechRecognitionControllerProvider =
    SpeechRecognitionControllerProvider._();

final class SpeechRecognitionControllerProvider
    extends
        $NotifierProvider<SpeechRecognitionController, SpeechRecognitionState> {
  SpeechRecognitionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechRecognitionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechRecognitionControllerHash();

  @$internal
  @override
  SpeechRecognitionController create() => SpeechRecognitionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechRecognitionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeechRecognitionState>(value),
    );
  }
}

String _$speechRecognitionControllerHash() =>
    r'6d7083b34c7bcbce58c9abcd26e6d6b0cb797e2c';

abstract class _$SpeechRecognitionController
    extends $Notifier<SpeechRecognitionState> {
  SpeechRecognitionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SpeechRecognitionState, SpeechRecognitionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpeechRecognitionState, SpeechRecognitionState>,
              SpeechRecognitionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
