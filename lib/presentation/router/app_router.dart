import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/movies/movies_screen.dart';
import '../screens/series/series_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/movies',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/movies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MoviesScreen(),
          ),
        ),
        GoRoute(
          path: '/series',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SeriesScreen(),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ActivityScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);

enum AppTab {
  movies('/movies', 'Movies', Icons.movie_outlined, Icons.movie),
  series('/series', 'Series', Icons.tv_outlined, Icons.tv),
  calendar('/calendar', 'Calendar', Icons.calendar_today_outlined, Icons.calendar_today),
  activity('/activity', 'Activity', Icons.download_outlined, Icons.download),
  settings('/settings', 'Settings', Icons.settings_outlined, Icons.settings);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppTab(this.path, this.label, this.icon, this.selectedIcon);

  static AppTab fromPath(String path) {
    return AppTab.values.firstWhere(
      (tab) => path.startsWith(tab.path),
      orElse: () => AppTab.movies,
    );
  }
}
