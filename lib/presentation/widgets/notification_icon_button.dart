import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notifications_provider.dart';

/// An icon button that displays a notification bell with an unread count badge.
///
/// Tapping this button navigates to the notifications screen. When embedded in
/// the adaptive navigation rail, set [showTooltip] to false: the rail mounts
/// and unmounts this widget on route changes, and a tooltip overlay being
/// dismissed mid-layout can corrupt the shell's LayoutBuilder on web.
class NotificationIconButton extends ConsumerWidget {
  /// Whether the button shows a long-press/hover tooltip.
  ///
  /// Disable it when embedded in the adaptive navigation rail, where a
  /// tooltip overlay dismissed mid-layout can corrupt the shell.
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
