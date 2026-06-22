import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class CloudinaryService {
  static const String cloudName = 'luxemarket';
  static const String uploadPreset = 'user_profiles';

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String sellerId,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    // Note: The product upload preset might be different from the profile one.
    // For now, I'll use a generic name or keep it flexible.
    // The user's prompt specified user_profiles for profiles.
    request.fields['upload_preset'] = 'luxemarket_products';

    request.fields['folder'] = 'luxemarket/products/$sellerId';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return data['secure_url'] as String;
  }

  /// Uploads a buyer's profile photo to Cloudinary from raw bytes.
  ///
  /// Previously this took a `dart:io.File` and called `imageFile.exists()` /
  /// `MultipartFile.fromPath(...)` — both unusable on Flutter Web. It now
  /// mirrors `uploadImage` above and works identically on every platform.
  static Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String userId,
  }) async {
    const String folder = 'user_profiles';

    debugPrint(
      '[CLOUDINARY] uploadProfileImage: Starting upload for userId=$userId, bytes=${bytes.length}',
    );

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.fields['public_id'] = userId;

    // Cloudinary supports overriding public_id, but it can cache older images.
    // By setting public_id to userId and folder to user_profiles, Cloudinary
    // puts the asset at user_profiles/{userId}.
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: '$userId.jpg'),
    );

    try {
      debugPrint('[CLOUDINARY] uploadProfileImage: Sending request to $uri');
      final streamedResponse = await request.send().timeout(
        AppConstants.uploadTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        '[CLOUDINARY] uploadProfileImage: Response status=${response.statusCode}',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          '[CLOUDINARY][ERROR] uploadProfileImage failed: status=${response.statusCode}, body=${response.body}',
        );
        throw Exception('Cloudinary upload failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final secureUrl = data['secure_url'] as String;
      debugPrint(
        '[CLOUDINARY][SUCCESS] uploadProfileImage uploaded: $secureUrl',
      );
      return secureUrl;
    } catch (e) {
      debugPrint('[CLOUDINARY][ERROR] Exception during Cloudinary upload: $e');
      rethrow;
    }
  }
}
