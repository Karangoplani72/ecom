import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'den9tz3ib';
  static const String uploadPreset = 'luxemarket_products';

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String sellerId,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

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
}
