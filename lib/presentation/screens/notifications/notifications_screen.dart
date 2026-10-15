import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: context.l10n.notificationsMarkAllRead,
                onPressed: () {
                  ref
                      .read(notificationActionsProvider.notifier)
                      .markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.notificationsAllMarkedRead),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: context.l10n.notificationsClearAll,
              onPressed: () => _showClearAllDialog(context, ref),
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : _buildNotificationsList(context, ref, notifications),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.notifications_off_outlined,
      title: context.l10n.notificationsEmptyTitle,
      subtitle: context.l10n.notificationsEmptySubtitle,
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
                content: Text(context.l10n.notificationsDismissed),
                duration: const Duration(seconds: 2),
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
        title: Text(context.l10n.notificationsClearAllTitle),
        content: Text(context.l10n.notificationsClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notificationActionsProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.notificationsAllCleared),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(context.l10n.notificationsClearAll),
          ),
        ],
      ),
    );
  }
}
