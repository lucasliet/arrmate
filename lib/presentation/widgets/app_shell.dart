import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../tour/app_tour_keys.dart';
import 'offline_status_banner.dart';

/// Main shell widget containing the app scaffold and navigation bar.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourKeys = ref.watch(appTourKeysProvider);
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

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return AppTab.fromPath(location).index;
  }

  void _onItemTapped(BuildContext context, int index) {
    final tab = AppTab.values[index];
    context.go(tab.path);
  }
}
