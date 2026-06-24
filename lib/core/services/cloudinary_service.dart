import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class CloudinaryService {
  // ── Public upload config (from .env) ──
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'flutter_unsigned';

  // ── Images (unsigned preset) ─────────────────────────────────────────────

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String sellerId,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = 'luxemarket/products/$sellerId'
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  // ── Profile image ────────────────────────────────────────────────────────

  static Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String userId,
    required int version,
  }) async {
    final publicId = 'user_profiles/${userId}_v$version';

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
            ),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['public_id'] = publicId
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: '$userId.jpg',
            ),
          );

    try {
      final streamed = await request.send().timeout(AppConstants.uploadTimeout);
      final responseBody = await streamed.stream.bytesToString();

      debugPrint('[CLOUDINARY] Profile upload status=${streamed.statusCode}');
      debugPrint('[CLOUDINARY] Profile upload body=$responseBody');

      if (streamed.statusCode != 200 && streamed.statusCode != 201) {
        throw Exception('Cloudinary upload failed: $responseBody');
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String;
      debugPrint('[CLOUDINARY][SUCCESS] url=$secureUrl');
      return secureUrl;
    } catch (e) {
      debugPrint('[CLOUDINARY][ERROR] $e');
      rethrow;
    }
  }
}
