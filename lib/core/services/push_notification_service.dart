import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:ecom/features/marketplace/presentation/controllers/communication_controller.dart';

// 1. Top-Level Background Handler (Must be outside any class so it can run when app is killed)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize other Firebase services in the background, do it here.
  debugPrint("Handling a background message: ${message.messageId}");
}

// 2. Riverpod Provider for the Notification Service
final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService();
});

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  PushNotificationService();

  Future<void> initialize() async {
    // 1. Request OS-level permissions (Critical for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push notification permissions.');
    } else {
      debugPrint('User declined or has not accepted permissions.');
      return;
    }

    // 2. Fetch the unique device token
    final String? token = await _fcm.getToken();
    if (token != null) {
      debugPrint('FCM Device Token: $token');
      // Link the token to the current user's profile via the Communication Controller
      // (Assumes a logged-in state; in production, call this after auth completes)
      // _ref.read(communicationControllerProvider.notifier).associateDeviceToken('current_user_id', token);
    }

    // 3. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      // Update backend with new token
      debugPrint('FCM Token Refreshed: $newToken');
    });

    // 4. Handle Foreground Messages (App is open and active)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      // Here you could trigger a local in-app snack bar or banner
    });

    // 5. Handle Background/Terminated Deep Links (User tapped the notification)
    _setupDeepLinking();
  }

  void _setupDeepLinking() async {
    // Scenario A: App was completely closed, user tapped notification to open it
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationRoute(initialMessage);
    }

    // Scenario B: App was in background (minimized), user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationRoute);
  }

  void _handleNotificationRoute(RemoteMessage message) {
    // Extract the deep link path from the FCM data payload.
    // Example Payload from your backend: { "route": "/seller/dashboard" }
    final route = message.data['route'];

    if (route != null) {
      // Use the global navigator key defined in router.dart to route contextualises
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        context.push(route);
      } else {
        debugPrint(
          "Warning: Tried to deep link but rootNavigatorKey context was null.",
        );
      }
    }
  }
}
