import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notifications_provider.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/notification_card.dart';

/// Screen that displays all in-app notifications.
///
/// Users can view, mark as read, and dismiss notifications.
/// Swipe left or right to dismiss a notification.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
                onPressed: () {
                  ref.read(notificationActionsProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: () => _showClearAllDialog(context, ref),
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(theme)
          : _buildNotificationsList(context, ref, notifications),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return EmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'No notifications',
      subtitle:
          'When you receive notifications from Radarr or Sonarr, they will appear here.',
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List notifications,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationActionsProvider.notifier)
                  .markAsRead(notification.id);
            }
            // Future: Navigate to related content based on metadata
            // e.g., movie details, series details, etc.
          },
          onDismiss: () {
            ref
                .read(notificationActionsProvider.notifier)
                .dismiss(notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification dismissed'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    // Re-add the notification would require storing it
                    // For simplicity, we don't implement undo
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will remove all notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notificationActionsProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}
