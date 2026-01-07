import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/notification/app_notification.dart';
import '../../domain/models/notification/ntfy_message.dart';
import 'logger_service.dart';

/// Key for storing the last poll timestamp in SharedPreferences.
/// This is shared between SSE (NtfyService) and polling.
const lastPollTimestampKey = 'ntfy_last_poll_timestamp';

/// Key for storing notifications in SharedPreferences.
const _notificationsKey = 'in_app_notifications';

/// Maximum number of notifications to store locally.
const _maxNotifications = 100;

/// Maximum age of notifications before auto-cleanup (7 days).
const _maxNotificationAge = Duration(days: 7);

/// Service for managing in-app notifications.
///
/// This service replaces the old [NotificationService] that used system
/// push notifications. Instead, notifications are stored locally and
/// displayed within the app's notification center.
class InAppNotificationService {
  final List<AppNotification> _notifications = [];

  /// Returns all notifications, sorted by timestamp (newest first).
  List<AppNotification> get notifications {
    final sorted = List<AppNotification>.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(sorted);
  }

  /// Returns the count of unread notifications.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initializes the service by loading notifications from local storage.
  Future<void> init() async {
    logger.info('[InAppNotificationService] Initializing');
    await _loadFromLocal();
    await _cleanupOldNotifications();
    logger.info(
      '[InAppNotificationService] Loaded ${_notifications.length} notifications',
    );
  }

  /// Adds a new notification.
  ///
  /// The notification is added to the list and persisted locally.
  /// If the list exceeds [_maxNotifications], the oldest notifications
  /// are removed.
  Future<void> addNotification(AppNotification notification) async {
    logger.debug(
      '[InAppNotificationService] Adding notification: ${notification.title}',
    );

    // Check for duplicate by id
    if (_notifications.any((n) => n.id == notification.id)) {
      logger.debug(
        '[InAppNotificationService] Duplicate notification ignored: ${notification.id}',
      );
      return;
    }

    _notifications.add(notification);

    // Trim to max size
    if (_notifications.length > _maxNotifications) {
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _notifications.removeRange(_maxNotifications, _notifications.length);
    }

    await _saveToLocal();
  }

  /// Creates and adds a notification from an [NtfyMessage].
  Future<AppNotification> addFromNtfyMessage(NtfyMessage message) async {
    final type = _inferNotificationType(message);
    final priority = _inferPriority(message);

    final notification = AppNotification(
      id: message.id,
      title: message.title ?? 'Arrmate',
      message: message.message ?? '',
      type: type,
      priority: priority,
      timestamp: message.timestamp,
      metadata: {
        'topic': message.topic,
        if (message.tags != null) 'tags': message.tags,
        if (message.click != null) 'click': message.click,
      },
    );

    await addNotification(notification);
    return notification;
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveToLocal();
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveToLocal();
  }

  /// Dismisses (removes) a notification.
  Future<void> dismiss(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveToLocal();
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToLocal();
  }

  /// Updates the last poll timestamp.
  ///
  /// Call this after receiving a message via SSE or polling
  /// to avoid re-fetching the same messages.
  static Future<void> updateLastPollTimestamp([int? timestamp]) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await prefs.setInt(lastPollTimestampKey, ts);
  }

  /// Gets the last poll timestamp.
  static Future<int> getLastPollTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastPollTimestampKey) ?? 0;
  }

  /// Infers the notification type from an ntfy message.
  NotificationType _inferNotificationType(NtfyMessage message) {
    final title = (message.title ?? '').toLowerCase();
    final msg = (message.message ?? '').toLowerCase();
    final tags = message.tags ?? [];

    // Check tags first
    if (tags.contains('x') || tags.contains('warning')) {
      return NotificationType.error;
    }
    if (tags.contains('white_check_mark') || tags.contains('heavy_check_mark')) {
      return NotificationType.imported;
    }
    if (tags.contains('arrow_down') || tags.contains('inbox_tray')) {
      return NotificationType.download;
    }

    // Check message content
    if (title.contains('failed') ||
        msg.contains('failed') ||
        title.contains('error') ||
        msg.contains('error')) {
      return NotificationType.error;
    }
    if (title.contains('imported') || msg.contains('imported')) {
      return NotificationType.imported;
    }
    if (title.contains('grabbed') ||
        msg.contains('grabbed') ||
        title.contains('download') ||
        msg.contains('download')) {
      return NotificationType.download;
    }
    if (title.contains('upgrade') ||
        msg.contains('upgrade') ||
        title.contains('updated') ||
        msg.contains('updated')) {
      return NotificationType.upgrade;
    }
    if (title.contains('warning') || msg.contains('warning')) {
      return NotificationType.warning;
    }

    return NotificationType.info;
  }

  /// Infers the priority from an ntfy message.
  NotificationPriority _inferPriority(NtfyMessage message) {
    final ntfyPriority = message.priority ?? 3;
    if (ntfyPriority >= 4) return NotificationPriority.high;
    if (ntfyPriority <= 2) return NotificationPriority.low;
    return NotificationPriority.medium;
  }

  /// Loads notifications from SharedPreferences.
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);
      if (jsonString == null) return;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      _notifications.clear();
      for (final json in jsonList) {
        try {
          _notifications.add(AppNotification.fromJson(json));
        } catch (e) {
          logger.warning(
            '[InAppNotificationService] Failed to parse notification: $e',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        '[InAppNotificationService] Failed to load notifications',
        e,
        stackTrace,
      );
    }
  }

  /// Saves notifications to SharedPreferences.
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e, stackTrace) {
      logger.error(
        '[InAppNotificationService] Failed to save notifications',
        e,
        stackTrace,
      );
    }
  }

  /// Removes notifications older than [_maxNotificationAge].
  Future<void> _cleanupOldNotifications() async {
    final cutoff = DateTime.now().subtract(_maxNotificationAge);
    final oldCount = _notifications.length;
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoff));

    if (_notifications.length != oldCount) {
      logger.info(
        '[InAppNotificationService] Cleaned up ${oldCount - _notifications.length} old notifications',
      );
      await _saveToLocal();
    }
  }
}
