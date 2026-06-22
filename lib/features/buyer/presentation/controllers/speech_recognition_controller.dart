import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'speech_recognition_controller.g.dart';

enum SpeechRecognitionStatus {
  idle,
  listening,
  processing,
  done,
  error,
  permissionDenied,
  notAvailable,
}

class SpeechRecognitionState {
  final SpeechRecognitionStatus status;
  final String partialTranscript;
  final String? errorMessage;

  const SpeechRecognitionState({
    required this.status,
    required this.partialTranscript,
    this.errorMessage,
  });

  SpeechRecognitionState copyWith({
    SpeechRecognitionStatus? status,
    String? partialTranscript,
    String? errorMessage,
  }) {
    return SpeechRecognitionState(
      status: status ?? this.status,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Friendly copy for the structured error codes speech_to_text's listen()
/// reports through onError once recognition is actually running (these are
/// NOT raw exceptions - they're documented codes like 'error_no_match').
/// See: https://pub.dev/packages/speech_to_text
String _friendlyListenErrorMessage(String? code) {
  switch (code) {
    case 'error_no_match':
      return "Didn't catch that. Tap mic to try again.";
    case 'error_speech_timeout':
      return 'No speech detected. Tap mic to try again.';
    case 'error_network':
    case 'error_network_timeout':
      return 'Network issue — check your connection and try again.';
    case 'error_audio_error':
      return "Couldn't access the microphone. Tap mic to try again.";
    case 'error_busy':
      return 'Speech recognizer is busy. Please wait a moment and try again.';
    case 'error_insufficient_permissions':
      return 'Microphone permission needed — tap to open settings.';
    default:
      return 'No speech detected. Tap mic to try again.';
  }
}

@riverpod
class SpeechRecognitionController extends _$SpeechRecognitionController {
  SpeechToText? _speech;
  bool _isInitialized = false;

  @override
  SpeechRecognitionState build() {
    ref.onDispose(() {
      _speech?.cancel();
    });

    return const SpeechRecognitionState(
      status: SpeechRecognitionStatus.idle,
      partialTranscript: '',
    );
  }

  SpeechToText get _getSpeech {
    return _speech ??= SpeechToText();
  }

  Future<void> startListening({String localeId = 'en_IN'}) async {
    if (!kIsWeb) {
      final permissionStatus = await Permission.microphone.status;
      if (permissionStatus.isPermanentlyDenied) {
        _setPermissionDenied();
        return;
      }

      if (!permissionStatus.isGranted) {
        final requestResult = await Permission.microphone.request();
        if (!requestResult.isGranted) {
          _setPermissionDenied();
          return;
        }
      }
    }

    try {
      final speech = _getSpeech;

      if (!_isInitialized) {
        final available = await speech.initialize(
          onStatus: (status) {
            if (!ref.mounted) return;
            if (status == 'listening') {
              state = state.copyWith(status: SpeechRecognitionStatus.listening);
            } else if (status == 'notListening' &&
                state.status != SpeechRecognitionStatus.error &&
                state.status != SpeechRecognitionStatus.permissionDenied) {
              state = state.copyWith(status: SpeechRecognitionStatus.done);
            }
          },
          onError: (errorNotification) {
            if (!ref.mounted) return;
            debugPrint(
              'SpeechRecognitionController: listen error - ${errorNotification
                  .errorMsg} '
                  '(permanent: ${errorNotification.permanent})',
            );
            state = SpeechRecognitionState(
              status: SpeechRecognitionStatus.error,
              partialTranscript: state.partialTranscript,
              errorMessage: _friendlyListenErrorMessage(
                  errorNotification.errorMsg),
            );
          },
        );
        _isInitialized = available;
        if (!available) {
          if (ref.mounted) {
            state = const SpeechRecognitionState(
              status: SpeechRecognitionStatus.notAvailable,
              partialTranscript: '',
              errorMessage: "Speech recognition isn't available on this device.",
            );
          }
          return;
        }
      }

      if (ref.mounted) {
        state = const SpeechRecognitionState(
          status: SpeechRecognitionStatus.listening,
          partialTranscript: '',
        );
      }

      await speech.listen(
        onResult: (result) {
          if (!ref.mounted) return;
          state = SpeechRecognitionState(
            status: result.finalResult
                ? SpeechRecognitionStatus.done
                : SpeechRecognitionStatus.processing,
            partialTranscript: result.recognizedWords,
          );
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
          localeId: localeId,
        ),
      );
    } on MissingPluginException catch (e) {
      // This means the speech_to_text plugin binding wasn't loaded by this
      // running app/browser session - almost always because the package was
      // added to pubspec.yaml after this session started, or a web build is
      // stale. It is NOT a permission or "no speech" problem. A code-level
      // retry can't fix it; the app/page needs a full restart.
      debugPrint('SpeechRecognitionController: plugin not registered - $e');
      _isInitialized = false;
      if (ref.mounted) {
        state = SpeechRecognitionState(
          status: SpeechRecognitionStatus.notAvailable,
          partialTranscript: '',
          errorMessage: kIsWeb
              ? 'Voice search needs a page refresh to finish loading. Please reload the page and try again.'
              : "Voice search isn't ready yet. Please fully close and reopen the app, then try again.",
        );
      }
    } catch (e) {
      debugPrint('SpeechRecognitionController: unexpected error - $e');
      if (ref.mounted) {
        state = const SpeechRecognitionState(
          status: SpeechRecognitionStatus.error,
          partialTranscript: '',
          errorMessage: 'No speech detected. Tap mic to try again.',
        );
      }
    }
  }

  void _setPermissionDenied() {
    if (ref.mounted) {
      state = const SpeechRecognitionState(
        status: SpeechRecognitionStatus.permissionDenied,
        partialTranscript: '',
        errorMessage: 'Microphone permission needed — tap to open settings.',
      );
    }
  }

  Future<void> stopListening() async {
    await _speech?.stop();
    if (ref.mounted) {
      state = state.copyWith(status: SpeechRecognitionStatus.done);
    }
  }

  Future<void> openSettings() async {
    if (!kIsWeb) {
      await openAppSettings();
    }
  }

  bool get isAvailable => _isInitialized;
}