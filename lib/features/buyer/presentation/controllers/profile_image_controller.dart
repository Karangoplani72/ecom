import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/common_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_image_state.dart';

part 'profile_image_controller.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
class ProfileImageController extends _$ProfileImageController {
  final ImagePicker _picker = ImagePicker();

  @override
  ProfileImageState build() {
    // Reset state if auth status changes (e.g. logout)
    ref.watch(firebaseAuthStateProvider);

    // Keep alive so state survives navigation away from the profile screen.
    // Without this the provider auto-disposes when the screen unmounts and
    // the uploaded image is lost when the user navigates back.
    ref.keepAlive();
    return ProfileImageState.initial();
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    debugPrint(
      '[PROFILE_UPLOAD] pickAndUploadImage: Triggered with source=$source',
    );

    // 1. Check internet connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('[PROFILE_UPLOAD][ERROR] No internet connection');
        state = const ProfileImageState(
          status: ProfileImageStatus.error,
          errorMessage:
              'No internet connection. Please check your network and try again.',
        );
        return;
      }
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][WARNING] Failed to check connectivity: $e');
    }

    // 2. Set loading state while picker opens
    state = const ProfileImageState(status: ProfileImageStatus.loading);

    // 3. Open image picker
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100, // We will compress manually in our repository/utils
      );
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][ERROR] Image picking failed: $e');
      state = ProfileImageState(
        status: ProfileImageStatus.error,
        errorMessage: 'Failed to access camera/gallery: ${e.toString()}',
      );
      return;
    }

    // 4. Handle user cancellation
    if (pickedFile == null) {
      debugPrint('[PROFILE_UPLOAD] Image picking cancelled by user');
      state = ProfileImageState.initial();
      return;
    }

    // 5. Read bytes — this is the cross-platform-safe step. `XFile.readAsBytes()`
    // works identically on web, mobile, and desktop, unlike `dart:io.File`
    // (whose `.path` is an unusable blob: URL on web).
    final Uint8List bytes;
    try {
      bytes = await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint(
        '[PROFILE_UPLOAD][ERROR] Failed to read picked file bytes: $e',
      );
      state = ProfileImageState(
        status: ProfileImageStatus.error,
        errorMessage: 'Failed to read the selected image. Please try again.',
      );
      return;
    }
    final String fileName = pickedFile.name;

    // 6. Show local preview immediately (bytes-based — safe on every platform)
    debugPrint(
      '[PROFILE_UPLOAD] Showing local preview immediately: $fileName (${bytes.length} bytes)',
    );
    state = ProfileImageState(
      status: ProfileImageStatus.uploading,
      localImageBytes: bytes,
    );

    // 7. Perform repository upload (validates, compresses, uploads, updates Firestore)
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.uploadProfileImage(
      bytes: bytes,
      fileName: fileName,
    );

    await result.fold(
      (failure) async {
        debugPrint('[PROFILE_UPLOAD][ERROR] Flow failed: ${failure.message}');
        if (!ref.mounted) return;
        state = ProfileImageState(
          status: ProfileImageStatus.error,
          localImageBytes: bytes,
          errorMessage: failure.message,
        );
      },
      (imageUrl) async {
        debugPrint(
          '[PROFILE_UPLOAD][SUCCESS] Flow completed successfully: $imageUrl',
        );

        // BELT-AND-SUSPENDERS:
        // We use cache-busting (?v=timestamp) so the URL is technically new,
        // but some aggressive caches might still be tricky.
        // Also, evicting the OLD url would be better, but since the new one
        // is what we are about to show, we ensure Flutter's memory cache is
        // clean for it just in case.
        PaintingBinding.instance.imageCache.evict(NetworkImage(imageUrl));

        if (!ref.mounted) return;
        state = ProfileImageState(
          status: ProfileImageStatus.success,
          imageUrl: imageUrl,
          localImageBytes: bytes,
        );
      },
    );
  }

  void reset() {
    state = ProfileImageState.initial();
  }
}

@riverpod
String? optimisticUserPhoto(Ref ref) {
  final uploadState = ref.watch(profileImageControllerProvider);
  final userProfile = ref.watch(currentUserProfileProvider).value;

  // 1. If we have a freshly uploaded image in the controller, use it immediately.
  if (uploadState.status == ProfileImageStatus.success &&
      uploadState.imageUrl != null) {
    return uploadState.imageUrl;
  }

  // 3. Fallback to the Firestore-persisted URL.
  return userProfile?.photoUrl;
}

/// A combined state for avatars across the app to show local preview
/// during upload and the best available URL afterwards.
class OptimisticProfile {
  final String? imageUrl;
  final Uint8List? localBytes;
  final bool isUploading;

  const OptimisticProfile({
    this.imageUrl,
    this.localBytes,
    this.isUploading = false,
  });
}

@riverpod
OptimisticProfile optimisticProfile(Ref ref) {
  final uploadState = ref.watch(profileImageControllerProvider);
  final userProfile = ref.watch(currentUserProfileProvider).value;

  final isUploading = uploadState.status == ProfileImageStatus.uploading;

  // Use local bytes if we are uploading OR if we just finished (to avoid flicker)
  // or even on error (so user sees what failed).
  final localBytes = (uploadState.status == ProfileImageStatus.uploading ||
          uploadState.status == ProfileImageStatus.success ||
          uploadState.status == ProfileImageStatus.error)
      ? uploadState.localImageBytes
      : null;

  // Prefer the freshly-uploaded URL from the controller
  final imageUrl = uploadState.imageUrl ?? userProfile?.photoUrl;

  return OptimisticProfile(
    imageUrl: imageUrl,
    localBytes: localBytes,
    isUploading: isUploading,
  );
}
