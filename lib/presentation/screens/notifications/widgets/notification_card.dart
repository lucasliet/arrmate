import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../domain/models/notification/app_notification.dart';

/// A card widget that displays an in-app notification.
///
/// Supports swipe to dismiss and tap to mark as read.
class NotificationCard extends StatelessWidget {
  /// The notification to display.
  final AppNotification notification;

  /// Callback when the notification is tapped.
  final VoidCallback? onTap;

  /// Callback when the notification is dismissed via swipe.
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        color: isUnread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(notification.timestamp),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final color = _getTypeColor(theme);
    final icon = _getTypeIcon();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Color _getTypeColor(ThemeData theme) {
    switch (notification.type) {
      case NotificationType.download:
        return Colors.blue;
      case NotificationType.error:
        return theme.colorScheme.error;
      case NotificationType.imported:
        return Colors.green;
      case NotificationType.upgrade:
        return Colors.purple;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.download:
        return Icons.download_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.imported:
        return Icons.check_circle_outline_rounded;
      case NotificationType.upgrade:
        return Icons.system_update_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }
}
