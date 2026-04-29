
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM initialization, topic subscription, and foreground notifications.
///
/// FCM is supported on Android, iOS, macOS, and Web.
/// On Windows/Linux desktop, FCM is not available — we skip initialization.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Whether FCM is available on the current platform.
  bool get _isFcmSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Initialize FCM: request permissions, subscribe to 'admin' topic,
  /// and set up foreground message handling.
  Future<void> initialize() async {
    if (!_isFcmSupported) {
      debugPrint('ℹ️ FCM not supported on this platform — skipping initialization.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ Notification permission denied.');
        return;
      }

      // Subscribe to the 'admin' topic for receiving order notifications
      if (!kIsWeb) {
        await messaging.subscribeToTopic('admin');
        debugPrint('✅ Subscribed to FCM topic: admin');
      } else {
        debugPrint('ℹ️ Topic subscription not supported on Web. Skipping.');
      }

      // Get and log the FCM token (useful for debugging)
      final token = await messaging.getToken();
      debugPrint('📱 FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  /// Handle messages received while the app is in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // The notification will automatically show on Android if the message
    // contains a notification payload. On desktop/web, you may need
    // flutter_local_notifications for custom display.
  }

  /// Handle when the user taps on a notification (background/terminated).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped:');
    debugPrint('   Data: ${message.data}');

    // You can navigate to the orders page here if needed
    final type = message.data['type'];
    if (type == 'new_order') {
      final orderId = message.data['orderId'];
      debugPrint('📦 Navigate to order: $orderId');
      // TODO: Navigate to order details page when implemented
    }
  }

  /// Unsubscribe from admin notifications (for logout or settings toggle).
  Future<void> unsubscribeFromAdmin() async {
    if (!_isFcmSupported) return;
    try {
      if (!kIsWeb) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('admin');
        debugPrint('🔕 Unsubscribed from FCM topic: admin');
      }
    } catch (e) {
      debugPrint('❌ FCM unsubscribe error: $e');
    }
  }
}
