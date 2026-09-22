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
            final selectedIndex = _calculateSelectedIndex(context);
            final content = Column(
              children: [
                if (windowClass.hasNavigationRail)
                  _DesktopHeader(tab: AppTab.values[selectedIndex]),
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

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 24, end: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tab.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Tooltip(
              message: 'Search (Ctrl/Cmd+K)',
              child: IconButton(
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.search),
              ),
            ),
            const NotificationIconButton(),
          ],
        ),
      ),
    ),
  );
}
