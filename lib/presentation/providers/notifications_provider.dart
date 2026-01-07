import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/in_app_notification_service.dart';
import '../../core/services/ntfy_service.dart';
import '../../domain/models/notification/app_notification.dart';

/// Provider for the [InAppNotificationService] singleton.
final inAppNotificationServiceProvider = Provider<InAppNotificationService>(
  (ref) {
    return InAppNotificationService();
  },
);

/// Provider for the [NtfyService].
///
/// This service handles SSE connections to ntfy.sh and polling for
/// missed notifications.
final ntfyServiceProvider = ChangeNotifierProvider<NtfyService>((ref) {
  final notificationService = ref.read(inAppNotificationServiceProvider);
  final ntfyService = NtfyService(notificationService);

  // Set up callback to trigger notification state updates
  ntfyService.onNotificationReceived = (_) {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  };

  return ntfyService;
});

/// Provider for the list of all notifications.
///
/// This provider returns a snapshot of all notifications from the
/// [InAppNotificationService], sorted by timestamp (newest first).
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  // Watch the ntfy service to get updates when new notifications arrive
  ref.watch(ntfyServiceProvider);
  return ref.read(inAppNotificationServiceProvider).notifications;
});

/// Provider for the count of unread notifications.
///
/// This is used to display a badge on the notification icon in the app bar.
final unreadNotificationCountProvider = Provider<int>((ref) {
  ref.watch(ntfyServiceProvider);
  return ref.read(inAppNotificationServiceProvider).unreadCount;
});

/// Provider for managing notification actions.
///
/// This notifier provides methods to mark notifications as read,
/// dismiss them, or clear all notifications.
final notificationActionsProvider =
    NotifierProvider<NotificationActionsNotifier, void>(() {
  return NotificationActionsNotifier();
});

/// Notifier for notification actions.
class NotificationActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Marks a notification as read.
  Future<void> markAsRead(String id) async {
    await ref.read(inAppNotificationServiceProvider).markAsRead(id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await ref.read(inAppNotificationServiceProvider).markAllAsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  /// Dismisses a notification.
  Future<void> dismiss(String id) async {
    await ref.read(inAppNotificationServiceProvider).dismiss(id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    await ref.read(inAppNotificationServiceProvider).clearAll();
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }
}
