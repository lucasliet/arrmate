import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logger_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Service responsible for managing local notifications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugins for Android and iOS.
  ///
  /// Requests necessary permissions on Android.
  Future<void> init() async {
    logger.info('[NotificationService] Initializing');
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();
  }

  /// Displays a local notification.
  ///
  /// [id] is the unique identifier for the notification.
  /// [title] is the notification title.
  /// [body] is the notification content.
  /// [payload] is an optional string payload attached to the notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    logger.debug('[NotificationService] Showing notification: $id - $title');
    try {
      const androidDetails = AndroidNotificationDetails(
        'arrmate_activity',
        'Activity Notifications',
        channelDescription: 'Notifications for grabs, imports and failures',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e, stackTrace) {
      logger.error(
        '[NotificationService] Error showing notification',
        e,
        stackTrace,
      );
    }
  }

  /// Cancels all pending and displayed notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
