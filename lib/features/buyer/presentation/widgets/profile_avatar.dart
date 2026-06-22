import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? localImageBytes;
  final String userName;
  final String? fallbackAsset;
  final double radius;
  final bool isUploading;
  final VoidCallback? onEditTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.localImageBytes,
    required this.userName,
    this.fallbackAsset,
    this.radius = 50,
    this.isUploading = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final initials = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : '?';

    // Decide what image provider to show
    Widget avatarImage;

    if (localImageBytes != null && localImageBytes!.isNotEmpty) {
      avatarImage = ClipOval(
        child: Image.memory(
          localImageBytes!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(context, initials, primaryColor),
        ),
      );
    } else if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      avatarImage = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint(
              '[PROFILE_UPLOAD][WARNING] CachedNetworkImage load error: $error',
            );
            return _buildPlaceholder(context, initials, primaryColor);
          },
        ),
      );
    } else {
      avatarImage = _buildPlaceholder(context, initials, primaryColor);
    }

    return Stack(
      children: [
        // Avatar Circle Container
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              avatarImage,
              if (isUploading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Camera Icon Overlay
        if (onEditTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: primaryColor,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: isUploading ? null : onEditTap,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    String initials,
    Color primaryColor,
  ) {
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      );
    }
    return _buildInitials(context, initials, primaryColor);
  }

  Widget _buildInitials(
    BuildContext context,
    String initials,
    Color primaryColor,
  ) {
    return Container(
      color: primaryColor.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
}
