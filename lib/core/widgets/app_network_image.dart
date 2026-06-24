import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl.isEmpty) {
      return _buildError(colorScheme);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (context, url) => Container(
        height: height,
        width: width,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildError(colorScheme),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Container(
      height: height,
      width: width,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colorScheme.primary.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}
