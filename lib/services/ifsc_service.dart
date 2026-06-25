import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class IfscBankDetails {
  final String bankName;
  final String branch;
  final String city;
  final String state;
  final String address;
  final String ifsc;

  const IfscBankDetails({
    required this.bankName,
    required this.branch,
    required this.city,
    required this.state,
    required this.address,
    required this.ifsc,
  });

  factory IfscBankDetails.fromJson(Map<String, dynamic> json) {
    return IfscBankDetails(
      bankName: json['BANK'] as String? ?? '',
      branch: json['BRANCH'] as String? ?? '',
      city: json['CITY'] as String? ?? '',
      state: json['STATE'] as String? ?? '',
      address: json['ADDRESS'] as String? ?? '',
      ifsc: json['IFSC'] as String? ?? '',
    );
  }
}

class IfscService {
  static const String _baseUrl = 'https://ifsc.razorpay.com';
  static const Duration _timeout = Duration(seconds: 10);

  // Simple in-memory cache to avoid repeated network calls for the same IFSC.
  static final Map<String, IfscBankDetails> _cache = {};

  static Future<IfscBankDetails> fetchByIfsc(String ifsc) async {
    final code = ifsc.trim().toUpperCase();

    if (code.isEmpty) {
      throw const IfscFetchException('IFSC code cannot be empty.');
    }

    final cached = _cache[code];
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/$code');

    http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const IfscFetchException(
        'Request timed out while verifying IFSC code.',
      );
    } catch (e) {
      throw IfscFetchException(
        'Failed to verify IFSC code. Check your internet connection.',
      );
    }

    if (response.statusCode == 404) {
      throw const IfscNotFoundException();
    }

    if (response.statusCode != 200) {
      throw IfscFetchException('Server error: ${response.statusCode}');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw const IfscFetchException(
        'Invalid response received while verifying IFSC code.',
      );
    }

    final details = IfscBankDetails.fromJson(json);
    _cache[code] = details;
    return details;
  }
}

class IfscNotFoundException implements Exception {
  const IfscNotFoundException();

  @override
  String toString() => 'Invalid IFSC code — bank not found.';
}

class IfscFetchException implements Exception {
  final String message;

  const IfscFetchException(this.message);

  @override
  String toString() => message;
}