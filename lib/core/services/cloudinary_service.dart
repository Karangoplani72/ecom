import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

class CloudinaryService {
  // ── Credentials (same account used in Anjalii's Nail Art — confirmed working) ──
  static const _cloudName = 'den9tz3ib';
  static const _apiKey = '431289785918396';
  static const _apiSecret = 'PXxDcpNcUQCgIeVr3YZ46wVqeUw';

  static const _productPreset = 'flutter_unsigned';

  // ── Product images (unsigned preset — seller) ────────────────────────────

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
          ..fields['upload_preset'] = _productPreset
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

  // ── Profile image — signed upload (works on Web + Android + iOS) ─────────
  //
  // Signed uploads bypass the unsigned-preset entirely — Cloudinary accepts
  // them based on HMAC-SHA1 of the params + API secret. This is the exact
  // same approach used in the Nail Art project where it works on web.

  static Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String userId,
    required int version,
  }) async {
    // Delete old image first (non-fatal if it doesn't exist)
    await _deleteOldProfileImage(userId);

    final publicId = 'user_profiles/$userId';
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();

    // Signature: SHA-1( "public_id=<id>&timestamp=<ts><secret>" )
    final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final signature = _sha1Hex(toSign);

    debugPrint(
      '[CLOUDINARY] uploadProfileImage signed: '
      'userId=$userId publicId=$publicId ts=$timestamp',
    );

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
            ),
          )
          ..fields['api_key'] = _apiKey
          ..fields['timestamp'] = timestamp
          ..fields['public_id'] = publicId
          ..fields['signature'] = signature
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

  // ── Delete old profile image (signed destroy) ────────────────────────────

  static Future<void> _deleteOldProfileImage(String userId) async {
    try {
      final publicId = 'user_profiles/$userId';
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // Params alphabetical order for Cloudinary signature
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = _sha1Hex(toSign);

      final response = await http
          .post(
            Uri.parse(
              'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
            ),
            body: {
              'public_id': publicId,
              'api_key': _apiKey,
              'timestamp': timestamp,
              'signature': signature,
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CLOUDINARY] delete status=${response.statusCode} body=${response.body}',
      );
    } catch (e) {
      // Non-fatal — first upload won't have an old image
      debugPrint('[CLOUDINARY] delete skipped (ok on first upload): $e');
    }
  }

  // ── SHA-1 hex (pure Dart — no crypto package needed) ────────────────────

  static String _sha1Hex(String input) {
    // SHA-1 implemented via Dart's built-in HMAC via dart:convert is not
    // available directly — we use the approach from dart:crypto workaround:
    // encode to UTF-8 bytes then compute SHA-1 manually.
    final bytes = utf8.encode(input);
    return _sha1(Uint8List.fromList(bytes));
  }

  /// Pure-Dart SHA-1. No external packages.
  static String _sha1(Uint8List message) {
    // Initial hash values
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;

    // Pre-processing: add padding
    final origLen = message.length;
    final List<int> msg = List<int>.from(message);
    msg.add(0x80);
    while (msg.length % 64 != 56) {
      msg.add(0x00);
    }
    // Append original length in bits as 64-bit big-endian
    final bitLen = origLen * 8;
    for (var i = 7; i >= 0; i--) {
      msg.add((bitLen >> (i * 8)) & 0xFF);
    }

    // Process each 512-bit (64-byte) chunk
    for (var offset = 0; offset < msg.length; offset += 64) {
      final chunk = msg.sublist(offset, offset + 64);
      final w = List<int>.filled(80, 0);

      for (var i = 0; i < 16; i++) {
        w[i] =
            ((chunk[i * 4] & 0xFF) << 24) |
            ((chunk[i * 4 + 1] & 0xFF) << 16) |
            ((chunk[i * 4 + 2] & 0xFF) << 8) |
            (chunk[i * 4 + 3] & 0xFF);
      }
      for (var i = 16; i < 80; i++) {
        w[i] = _rotl32(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }

      var a = h0, b = h1, c = h2, d = h3, e = h4;

      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotl32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotl32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return [
      h0,
      h1,
      h2,
      h3,
      h4,
    ].map((v) => v.toRadixString(16).padLeft(8, '0')).join();
  }

  static int _rotl32(int value, int shift) {
    final s = shift & 31;
    return ((value << s) | ((value & 0xFFFFFFFF) >> (32 - s))) & 0xFFFFFFFF;
  }
}
