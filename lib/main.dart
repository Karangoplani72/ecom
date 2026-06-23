import 'package:ecom/app.dart';
import 'package:ecom/firebase_options.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Initialize push notifications
  try {
    await container.read(pushNotificationServiceProvider).initialize();
  } catch (e) {
    debugPrint('Failed to initialize push notifications: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EcomApp(),
    ),
  );
}
