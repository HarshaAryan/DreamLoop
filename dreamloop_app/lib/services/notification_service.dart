import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// NotificationService — handles Firebase Cloud Messaging setup and handling.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: permission granted');
      } else {
        debugPrint(
          'FCM: permission not granted (${settings.authorizationStatus})',
        );
      }

      final token = await messaging.getToken();
      debugPrint('FCM token: $token');

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenFromNotification);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'New update';
    final body = message.notification?.body ?? 'You have a new notification.';
    debugPrint('FCM foreground: $title - $body');
  }

  void _handleOpenFromNotification(RemoteMessage message) {
    debugPrint('FCM opened app from notification: ${message.messageId}');
  }

  /// Local fallback for UX events while server-side push is being wired.
  void showLocalNotification({required String title, required String body}) {
    debugPrint('Local notification fallback: $title - $body');
  }
}
