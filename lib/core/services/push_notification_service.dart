import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/core/providers/common_providers.dart';

// 1. Top-Level Background Handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

// 2. Riverpod Provider for the Notification Service
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Ref _ref;
  String? _queuedToken;

  PushNotificationService(this._ref) {
    // Listen to user auth state to associate token once logged in
    _ref.listen(currentUserIdProvider, (previous, next) {
      if (next != null && _queuedToken != null) {
         _saveTokenToBackend(next, _queuedToken!);
      }
    });
  }

  Future<void> initialize() async {
    // 1. Request OS-level permissions
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
      _handleNewToken(token);
    }

    // 3. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _handleNewToken(newToken);
    });

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
    });

    // 5. Deep Linking setup
    _setupDeepLinking();
  }

  void _handleNewToken(String token) {
     final userId = _ref.read(currentUserIdProvider);
     if (userId != null) {
        _saveTokenToBackend(userId, token);
     } else {
        _queuedToken = token;
     }
  }

  void _saveTokenToBackend(String userId, String token) {
     _ref.read(authRepositoryProvider).updateFCMToken(userId, token);
     _queuedToken = null;
  }

  void _setupDeepLinking() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationRoute(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationRoute);
  }

  void _handleNotificationRoute(RemoteMessage message) {
    final route = message.data['route'];

    if (route != null) {
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
