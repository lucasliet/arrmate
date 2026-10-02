import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../adaptive/content_layout.dart';
import '../adaptive/window_class.dart';
import '../router/app_router.dart';
import '../tour/app_tour_keys.dart';
import 'notification_icon_button.dart';
import 'offline_status_banner.dart';

/// Main shell widget containing the app scaffold and navigation bar.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourKeys = ref.watch(appTourKeysProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = WindowClass.fromWidth(constraints.maxWidth);
        final location = GoRouterState.of(context).matchedLocation;
        final selectedIndex = _calculateSelectedIndex(context);
        final showRailNotifications = !AppTab.values.any(
          (tab) => tab.path == location,
        );
        final content = Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(child: child),
          ],
        );

        return Scaffold(
          // Keep the page at the same child position across navigation changes.
          body: Row(
            children: [
              if (windowClass.hasNavigationRail)
                NavigationRail(
                  key: tourKeys.navBarKey,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                  extended: windowClass.hasExtendedNavigation,
                  scrollable: true,
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/icon_mark.png',
                          width: 24,
                          height: 24,
                        ),
                        if (windowClass.hasExtendedNavigation) ...[
                          const SizedBox(width: 12),
                          Text(
                            'ARRMATE',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  selectedIndex: selectedIndex,
                  trailing: showRailNotifications
                      ? const NotificationIconButton(showTooltip: false)
                      : null,
                  trailingAtBottom: true,
                  onDestinationSelected: (index) =>
                      _onItemTapped(context, index),
                  destinations: AppTab.values
                      .map(
                        (tab) => NavigationRailDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.selectedIcon),
                          label: Text(tab.label),
                        ),
                      )
                      .toList(),
                )
              else
                const SizedBox.shrink(),
              if (windowClass.hasNavigationRail)
                const VerticalDivider(width: 1)
              else
                const SizedBox.shrink(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ContentLayout.maximumContentWidth,
                    ),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: windowClass == WindowClass.compact
              ? NavigationBar(
                  key: tourKeys.navBarKey,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(context, index),
                  destinations: AppTab.values
                      .map(
                        (tab) => NavigationDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.selectedIcon),
                          label: tab.label,
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return AppTab.fromPath(location).index;
  }

  void _onItemTapped(BuildContext context, int index) {
    final tab = AppTab.values[index];
    context.go(tab.path);
  }
}
