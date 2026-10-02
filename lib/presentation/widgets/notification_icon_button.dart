import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';

/// An icon button that displays a notification bell with an unread count badge.
///
/// Tapping this button navigates to the notifications screen. When embedded in
/// the adaptive navigation rail, set [showTooltip] to false. The rail inserts
/// this button only on routes outside the primary tabs, so the tooltip overlay
/// is not needed there.
class NotificationIconButton extends ConsumerWidget {
  /// Whether the button shows a long-press/hover tooltip.
  ///
  /// The navigation rail passes false. That button is inserted only while the
  /// current route is outside the primary tabs.
  final bool showTooltip;

  const NotificationIconButton({super.key, this.showTooltip = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final button = IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: showTooltip ? 'Notifications' : null,
      onPressed: () => context.push('/notifications'),
    );

    if (showTooltip) return button;
    return Semantics(label: 'Notifications', button: true, child: button);
  }
}
