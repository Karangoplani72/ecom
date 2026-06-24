import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the global Dio API Client.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.addAll([
    // App Check & Auth Interceptor
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final appCheckToken = await FirebaseAppCheck.instance.getToken();
          if (appCheckToken != null) {
            options.headers['X-Firebase-AppCheck'] = appCheckToken;
          }
        } catch (_) {}
        return handler.next(options);
      },
    ),
    
    // Logging Interceptor
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: kDebugMode,
      responseHeader: true,
      responseBody: kDebugMode,
      error: true,
      logPrint: (obj) {
        if (kDebugMode) {
          debugPrint('[API_CLIENT] $obj');
        }
      },
    ),
  ]);

  return dio;
});
