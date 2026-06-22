import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../constants/app_constants.dart';

class ImageUtils {
  static const List<String> _validExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
  ];

  /// Compresses the given image bytes to a maximum width of
  /// [AppConstants.maxImageWidth] at [AppConstants.imageQuality]% quality.
  ///
  /// Operates on raw bytes (not `dart:io.File`) so it behaves identically on
  /// web, mobile, and desktop. `flutter_image_compress` does not reliably
  /// support the web target, so on web we just return the original bytes —
  /// the browser-side picker has already produced a reasonably sized image.
  static Future<Uint8List> compressImage(Uint8List bytes) async {
    if (kIsWeb) {
      debugPrint(
        '[PROFILE_UPLOAD] compressImage: Web platform detected, skipping compression',
      );
      return bytes;
    }

    try {
      debugPrint(
        '[PROFILE_UPLOAD] compressImage: Input size = ${bytes.length} bytes',
      );

      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: AppConstants.imageQuality,
        minWidth: AppConstants.maxImageWidth,
        minHeight: AppConstants.maxImageWidth,
        format: CompressFormat.jpeg,
      );

      debugPrint(
        '[PROFILE_UPLOAD] compressImage: Compressed size = ${compressed.length} bytes',
      );
      return compressed;
    } catch (e) {
      debugPrint(
        '[PROFILE_UPLOAD][ERROR] compressImage: Failed to compress image: $e. Using original bytes.',
      );
      return bytes;
    }
  }

  /// Validates the image type from the picked file's *name*, not its path.
  ///
  /// `XFile.path` is a blob: URL with no extension on Flutter Web, which is
  /// why this used to reject every web upload. `XFile.name` always carries
  /// the original filename (e.g. "photo.jpg") on every platform, so we
  /// validate against that instead.
  static bool isValidImageType(String fileName) {
    final lower = fileName.toLowerCase();
    final isValid = _validExtensions.any((ext) => lower.endsWith(ext));

    debugPrint(
      '[PROFILE_UPLOAD] isValidImageType: fileName=$fileName, isValid=$isValid',
    );
    return isValid;
  }

  /// Checks if the byte length is within the maximum allowed size.
  static bool isWithinSizeLimit(Uint8List bytes, int maxMB) {
    final maxBytes = maxMB * 1024 * 1024;
    final isWithin = bytes.length <= maxBytes;

    debugPrint(
      '[PROFILE_UPLOAD] isWithinSizeLimit: size=${bytes.length} bytes, max=$maxBytes bytes, isWithin=$isWithin',
    );
    return isWithin;
  }
}
