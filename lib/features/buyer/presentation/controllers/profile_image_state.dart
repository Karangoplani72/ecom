import 'dart:typed_data';

enum ProfileImageStatus { initial, loading, uploading, success, error }

class ProfileImageState {
  final ProfileImageStatus status;
  final String? imageUrl;
  final Uint8List? localImageBytes;
  final String? errorMessage;

  const ProfileImageState({
    required this.status,
    this.imageUrl,
    this.localImageBytes,
    this.errorMessage,
  });

  factory ProfileImageState.initial() {
    return const ProfileImageState(status: ProfileImageStatus.initial);
  }

  ProfileImageState copyWith({
    ProfileImageStatus? status,
    String? imageUrl,
    Uint8List? localImageBytes,
    String? errorMessage,
  }) {
    return ProfileImageState(
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      localImageBytes: localImageBytes ?? this.localImageBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
