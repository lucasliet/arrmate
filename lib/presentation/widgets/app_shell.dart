import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    if (!kIsWeb) {
      return Scaffold(
        body: Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          key: tourKeys.navBarKey,
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(context, index),
          destinations: AppTab.values.map((tab) {
            return NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            );
          }).toList(),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            context.go('/search'),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            context.go('/search'),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
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
              body: windowClass.hasNavigationRail
                  ? Row(
                      children: [
                        NavigationRail(
                          key: tourKeys.navBarKey,
                          extended: windowClass.hasExtendedNavigation,
                          selectedIndex: selectedIndex,
                          trailing: showRailNotifications
                              ? const NotificationIconButton()
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
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: content),
                      ],
                    )
                  : content,
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
        ),
      ),
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
