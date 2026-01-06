import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/notification/ntfy_message.dart';
import '../../domain/models/settings/notification_settings.dart';
import 'logger_service.dart';

const _backgroundPollingTaskName = 'arrmate_ntfy_polling';

/// Key for storing the last poll timestamp in SharedPreferences.
/// This is shared between SSE (NtfyService) and background polling.
const lastPollTimestampKey = 'ntfy_last_poll_timestamp';
const _ntfyTopicKey = 'ntfy_topic_for_background';

/// Top-level callback dispatcher for WorkManager.
///
/// This must be a top-level function (not a method or closure) for WorkManager to invoke it.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _backgroundPollingTaskName) {
      return await BackgroundNotificationService.pollNotifications();
    }
    return true;
  });
}

/// Service for background polling of ntfy notifications using WorkManager.
///
/// This service runs periodic background tasks to fetch notifications
/// when the app is not in the foreground. The timestamp is shared with
/// [NtfyService] to avoid duplicate notifications.
class BackgroundNotificationService {
  /// Initializes WorkManager with the callback dispatcher.
  static Future<void> initialize() async {
    logger.info('[BackgroundNotificationService] Initializing WorkManager');
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// Starts periodic background polling for the given [topic].
  ///
  /// [intervalMinutes] controls how often the polling task runs.
  static Future<void> startPolling(
    String topic, {
    int intervalMinutes = 30,
  }) async {
    logger.info(
      '[BackgroundNotificationService] Starting background polling (interval: ${intervalMinutes}min)',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ntfyTopicKey, topic);

    // Only set timestamp if not already set (preserve for missed notifications)
    if (!prefs.containsKey(lastPollTimestampKey)) {
      await updateLastPollTimestamp();
    }

    await Workmanager().cancelByUniqueName(_backgroundPollingTaskName);
    await Workmanager().registerPeriodicTask(
      _backgroundPollingTaskName,
      _backgroundPollingTaskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    logger.info('[BackgroundNotificationService] Periodic task registered');
  }

  /// Stops background polling.
  static Future<void> stopPolling() async {
    logger.info('[BackgroundNotificationService] Stopping background polling');
    await Workmanager().cancelByUniqueName(_backgroundPollingTaskName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ntfyTopicKey);
  }

  /// Updates the shared last poll timestamp.
  /// Call this from NtfyService when SSE receives a message.
  static Future<void> updateLastPollTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      lastPollTimestampKey,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Fetches any missed notifications since the last poll/SSE message.
  ///
  /// Call this when the app opens to catch up on notifications
  /// that arrived while the app was closed.
  static Future<void> fetchMissedNotifications(String topic) async {
    logger.info(
      '[BackgroundNotificationService] Fetching missed notifications',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ntfyTopicKey, topic);

    await pollNotifications();
  }

  /// Polls ntfy.sh for new messages since the last poll.
  static Future<bool> pollNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final topic = prefs.getString(_ntfyTopicKey);
      final lastPoll = prefs.getInt(lastPollTimestampKey) ?? 0;

      if (topic == null || topic.isEmpty) {
        return true;
      }

      final url = Uri.parse(
        'https://${NotificationSettings.ntfyServer}/$topic/json?poll=1&since=$lastPoll',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        final notifications = FlutterLocalNotificationsPlugin();

        await notifications.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );

        int notificationId = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final message = NtfyMessage.tryParse(json);

            if (message != null && message.isMessage) {
              await notifications.show(
                notificationId++,
                message.title ?? 'Arrmate',
                message.message ?? '',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'arrmate_activity',
                    'Activity Notifications',
                    channelDescription:
                        'Notifications for grabs, imports and failures',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                ),
              );
            }
          } catch (_) {
            continue;
          }
        }

        await updateLastPollTimestamp();
      }

      return true;
    } catch (e) {
      logger.error('[BackgroundNotificationService] Polling failed', e);
      return false;
    }
  }
}
