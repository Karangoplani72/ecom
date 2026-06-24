import 'package:ecom/app.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/services/push_notification_service.dart';
import 'package:ecom/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final flavor = const String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  await dotenv.load(fileName: flavor == 'prod' ? '.env.prod' : '.env.dev');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check
  // Web: ReCaptchaV3Provider is required — without it activate() is a no-op
  // and any getToken() call will throw "activate() must be called first".
  // Android debug: AndroidDebugProvider avoids Play Integrity attestation in dev.
  // The site key below is the PUBLIC reCAPTCHA v3 key from the Firebase console
  // (Firebase > App Check > Apps > Web > reCAPTCHA v3 > Site key).
  await FirebaseAppCheck.instance.activate(
    // ignore: avoid_redundant_argument_values
    webProvider: ReCaptchaV3Provider(
      '6LeXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    ), // TODO: replace with your reCAPTCHA v3 site key
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  // Setup Global Error Handling with Crashlytics (not supported on web yet)
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Initialize Analytics
  FirebaseAnalytics.instance;

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize push notifications
  try {
    await container.read(pushNotificationServiceProvider).initialize();
  } catch (e) {
    debugPrint('Failed to initialize push notifications: $e');
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const EcomApp()),
  );
}
