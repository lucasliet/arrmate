import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/movies/movies_screen.dart';
import '../screens/movies/movie_details_screen.dart';
import '../screens/series/series_screen.dart';
import '../screens/series/series_details_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/instance_edit_screen.dart';
import '../screens/settings/logs_screen.dart';
import '../screens/settings/health_screen.dart';
import '../screens/settings/quality_profiles_screen.dart';
import '../widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/movies',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/movies',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MoviesScreen()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return MovieDetailsScreen(movieId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/series',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SeriesScreen()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return SeriesDetailsScreen(seriesId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ActivityScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
          routes: [
            GoRoute(
              path: 'instance/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return InstanceEditScreen(instanceId: id == 'new' ? null : id);
              },
            ),
            GoRoute(
              path: 'logs',
              builder: (context, state) => const LogsScreen(),
            ),
            GoRoute(
              path: 'health',
              builder: (context, state) => const HealthScreen(),
            ),
            GoRoute(
              path: 'quality-profiles',
              builder: (context, state) => const QualityProfilesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

enum AppTab {
  movies('/movies', 'Movies', Icons.movie_outlined, Icons.movie),
  series('/series', 'Series', Icons.tv_outlined, Icons.tv),
  calendar(
    '/calendar',
    'Calendar',
    Icons.calendar_today_outlined,
    Icons.calendar_today,
  ),
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
