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
    ref.watch(firebaseAuthStateProvider);
    ref.keepAlive();
    return ProfileImageState.initial();
  }

  Future<void> pickAndUploadImage(ImageSource source) async {
    debugPrint('[PROFILE_UPLOAD] pickAndUploadImage: source=$source');

    // 1. Connectivity check
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        debugPrint('[PROFILE_UPLOAD][ERROR] No internet');
        state = const ProfileImageState(
          status: ProfileImageStatus.error,
          errorMessage:
              'No internet connection. Please check your network and try again.',
        );
        return;
      }
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][WARNING] Connectivity check failed: $e');
    }

    // 2. Loading state while picker opens
    state = const ProfileImageState(status: ProfileImageStatus.loading);

    // 3. Pick image
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: source, imageQuality: 100);
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][ERROR] Picker failed: $e');
      state = ProfileImageState(
        status: ProfileImageStatus.error,
        errorMessage: 'Failed to access camera/gallery: ${e.toString()}',
      );
      return;
    }

    // 4. User cancelled
    if (pickedFile == null) {
      debugPrint('[PROFILE_UPLOAD] Cancelled by user');
      state = ProfileImageState.initial();
      return;
    }

    // 5. Read bytes (cross-platform: XFile.readAsBytes() works on web + native)
    final Uint8List bytes;
    try {
      bytes = await pickedFile.readAsBytes();
    } catch (e) {
      debugPrint('[PROFILE_UPLOAD][ERROR] Failed to read bytes: $e');
      state = ProfileImageState(
        status: ProfileImageStatus.error,
        errorMessage: 'Failed to read the selected image. Please try again.',
      );
      return;
    }
    final fileName = pickedFile.name;
    debugPrint('[PROFILE_UPLOAD] Picked: $fileName (${bytes.length} bytes)');

    // 6. Capture the CURRENT photoUrl BEFORE we start uploading so we can
    // evict it from Flutter's image cache once the upload succeeds.
    final previousUrl = ref.read(currentUserProfileProvider).value?.photoUrl;

    // 7. Show local preview immediately
    state = ProfileImageState(
      status: ProfileImageStatus.uploading,
      localImageBytes: bytes,
    );

    // 8. Upload via repository
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.uploadProfileImage(
      bytes: bytes,
      fileName: fileName,
    );

    await result.fold(
      (failure) async {
        debugPrint('[PROFILE_UPLOAD][ERROR] Upload failed: ${failure.message}');
        if (!ref.mounted) return;
        state = ProfileImageState(
          status: ProfileImageStatus.error,
          localImageBytes: bytes,
          errorMessage: failure.message,
        );
      },
      (imageUrl) async {
        debugPrint('[PROFILE_UPLOAD][SUCCESS] url=$imageUrl');

        // CRITICAL FIX: Evict the OLD url from Flutter's memory cache, not
        // the new one. The old entry is what causes the stale image to
        // appear when CachedNetworkImage or Image.network reloads. We also
        // evict the new url in case it somehow got pre-cached as a broken
        // entry, but the old eviction is what actually fixes the bug.
        if (previousUrl != null && previousUrl.isNotEmpty) {
          PaintingBinding.instance.imageCache.evict(NetworkImage(previousUrl));
          debugPrint(
            '[PROFILE_UPLOAD] Evicted old image from cache: $previousUrl',
          );
        }
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

  // CRITICAL FIX: Return the fresh URL from a completed upload first.
  if (uploadState.status == ProfileImageStatus.success &&
      uploadState.imageUrl != null) {
    return uploadState.imageUrl;
  }

  // During active upload there is no URL yet — fall back to Firestore profile.
  // The avatar widget handles local bytes separately via optimisticProfile.
  return userProfile?.photoUrl;
}

/// Combined optimistic state: local bytes for immediate preview during upload,
/// best available URL afterwards.
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

  // Expose local bytes during upload, on success (to avoid flicker while
  // CachedNetworkImage fetches the new URL), and on error (show what failed).
  final localBytes = switch (uploadState.status) {
    ProfileImageStatus.uploading ||
    ProfileImageStatus.success ||
    ProfileImageStatus.error => uploadState.localImageBytes,
    _ => null,
  };

  // Prefer the freshly-uploaded URL; fall back to Firestore profile URL.
  final imageUrl = uploadState.imageUrl ?? userProfile?.photoUrl;

  return OptimisticProfile(
    imageUrl: imageUrl,
    localBytes: localBytes,
    isUploading: isUploading,
  );
}
