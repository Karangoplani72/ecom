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

    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
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
        );
      },
      errorBuilder: (context, error, stackTrace) {
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
      },
    );
  }
}
