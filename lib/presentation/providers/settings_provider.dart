import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../../domain/models/settings/notification_settings.dart';
import '../../domain/models/movie/movie_sort.dart';
import '../../domain/models/series/series_sort.dart';
import '../../core/services/ntfy_service.dart';
import '../../core/services/logger_service.dart';
import 'notifications_provider.dart';

/// Provider for managing application settings (theme, layout, notifications).
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

/// Defines the layout mode for lists (Grid or List).
enum ViewMode {
  grid,
  list;

  /// Returns the display label for the view mode.
  String get label {
    switch (this) {
      case ViewMode.grid:
        return 'Grid';
      case ViewMode.list:
        return 'List';
    }
  }
}

/// State for [SettingsNotifier].
class SettingsState {
  /// The current color scheme.
  final AppColorScheme colorScheme;

  /// The current appearance setting (light/dark/system).
  final AppAppearance appearance;

  /// The preference for item display in lists (Grid/List).
  final ViewMode viewMode;

  /// The current notification settings.
  final NotificationSettings notifications;

  /// The persisted movie sort/filter options.
  final MovieSort movieSort;

  /// The persisted series sort/filter options.
  final SeriesSort seriesSort;

  /// The tab to show when the app starts.
  final AppTab homeTab;

  const SettingsState({
    this.colorScheme = AppColorScheme.blue,
    this.appearance = AppAppearance.system,
    this.viewMode = ViewMode.grid,
    this.notifications = const NotificationSettings(),
    this.movieSort = const MovieSort(),
    this.seriesSort = const SeriesSort(),
    this.homeTab = AppTab.movies,
  });

  SettingsState copyWith({
    AppColorScheme? colorScheme,
    AppAppearance? appearance,
    ViewMode? viewMode,
    NotificationSettings? notifications,
    MovieSort? movieSort,
    SeriesSort? seriesSort,
    AppTab? homeTab,
  }) {
    return SettingsState(
      colorScheme: colorScheme ?? this.colorScheme,
      appearance: appearance ?? this.appearance,
      viewMode: viewMode ?? this.viewMode,
      notifications: notifications ?? this.notifications,
      movieSort: movieSort ?? this.movieSort,
      seriesSort: seriesSort ?? this.seriesSort,
      homeTab: homeTab ?? this.homeTab,
    );
  }
}

/// Manages user settings and persists them to SharedPreferences.
class SettingsNotifier extends Notifier<SettingsState> {
  static const _colorSchemeKey = 'color_scheme';
  static const _appearanceKey = 'appearance';
  static const viewModeKey = 'view_mode';
  static const _notificationsKey = 'notification_settings';
  static const _homeTabKey = 'home_tab';
  static const _movieSortKey = 'movie_sort';
  static const _seriesSortKey = 'series_sort';

  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final colorSchemeName = prefs.getString(_colorSchemeKey);
    final appearanceName = prefs.getString(_appearanceKey);
    final viewModeName = prefs.getString(viewModeKey);
    final notificationsJson = prefs.getString(_notificationsKey);
    final homeTabName = prefs.getString(_homeTabKey);
    final movieSortJson = prefs.getString(_movieSortKey);
    final seriesSortJson = prefs.getString(_seriesSortKey);

    final notifications = _parseNotificationSettings(notificationsJson);
    final movieSort = _parseMovieSort(movieSortJson);
    final seriesSort = _parseSeriesSort(seriesSortJson);

    state = state.copyWith(
      colorScheme: colorSchemeName != null
          ? AppColorScheme.values.firstWhere(
              (e) => e.name == colorSchemeName,
              orElse: () => AppColorScheme.blue,
            )
          : null,
      appearance: appearanceName != null
          ? AppAppearance.values.firstWhere(
              (e) => e.name == appearanceName,
              orElse: () => AppAppearance.system,
            )
          : null,
      viewMode: viewModeName != null
          ? ViewMode.values.firstWhere(
              (e) => e.name == viewModeName,
              orElse: () => ViewMode.grid,
            )
          : ViewMode.grid,
      notifications: notifications,
      homeTab: homeTabName != null
          ? AppTab.values.firstWhere(
              (e) => e.name == homeTabName,
              orElse: () => AppTab.movies,
            )
          : AppTab.movies,
      movieSort: movieSort,
      seriesSort: seriesSort,
    );

    if (notifications.enabled && notifications.ntfyTopic != null) {
      try {
        logger.info('[SettingsNotifier] Connecting to ntfy on startup');
        final ntfyService = ref.read(ntfyServiceProvider);
        await ntfyService.connect(notifications.ntfyTopic!);

        // Fetch any missed notifications when app opens
        logger.info('[SettingsNotifier] Fetching missed notifications');
        await ntfyService.fetchMissedNotifications(notifications.ntfyTopic!);
      } catch (e, stack) {
        logger.error(
          '[SettingsNotifier] Failed to connect to ntfy on startup',
          e,
          stack,
        );
        // Continue without notifications - don't leave app in inconsistent state
      }
    }
  }

  NotificationSettings _parseNotificationSettings(String? jsonString) {
    if (jsonString == null) return const NotificationSettings();
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return NotificationSettings.fromJson(data);
    } catch (e, stack) {
      logger.error(
        '[SettingsNotifier] Error parsing notification settings',
        e,
        stack,
      );
      return const NotificationSettings();
    }
  }

  MovieSort _parseMovieSort(String? jsonString) {
    if (jsonString == null) return const MovieSort();
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return MovieSort.fromJson(data);
    } catch (e, stack) {
      logger.error('[SettingsNotifier] Error parsing movie sort', e, stack);
      return const MovieSort();
    }
  }

  SeriesSort _parseSeriesSort(String? jsonString) {
    if (jsonString == null) return const SeriesSort();
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return SeriesSort.fromJson(data);
    } catch (e, stack) {
      logger.error('[SettingsNotifier] Error parsing series sort', e, stack);
      return const SeriesSort();
    }
  }

  /// Sets and persists the app color scheme.
  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, scheme.name);
  }

  /// Sets and persists the app appearance (Light, Dark, System).
  Future<void> setAppearance(AppAppearance appearance) async {
    state = state.copyWith(appearance: appearance);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKey, appearance.name);
  }

  /// Sets and persists the list view mode (Grid, List).
  Future<void> setViewMode(ViewMode mode) async {
    state = state.copyWith(viewMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(viewModeKey, mode.name);
  }

  /// Sets and persists the home tab preference.
  Future<void> setHomeTab(AppTab tab) async {
    state = state.copyWith(homeTab: tab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homeTabKey, tab.name);
  }

  /// Sets and persists movie sort options.
  Future<void> setMovieSort(MovieSort sort) async {
    state = state.copyWith(movieSort: sort);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movieSortKey, jsonEncode(sort.toJson()));
  }

  /// Sets and persists series sort options.
  Future<void> setSeriesSort(SeriesSort sort) async {
    state = state.copyWith(seriesSort: sort);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seriesSortKey, jsonEncode(sort.toJson()));
  }

  /// Updates notification settings and manages the ntfy connection.
  ///
  /// With in-app notifications, there's no background polling.
  /// Notifications are received via SSE when the app is open.
  Future<void> updateNotifications(NotificationSettings notifications) async {
    state = state.copyWith(notifications: notifications);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.toJson()),
    );

    final ntfyService = ref.read(ntfyServiceProvider);

    if (notifications.enabled && notifications.ntfyTopic != null) {
      logger.info('[SettingsNotifier] Enabling ntfy notifications');
      await ntfyService.connect(notifications.ntfyTopic!);
    } else {
      logger.info('[SettingsNotifier] Disabling ntfy notifications');
      await ntfyService.disconnect();
    }
  }

  /// Generates a random topic for ntfy and enables notifications.
  Future<void> generateNtfyTopic() async {
    final topic = NtfyService.generateTopic();
    final updated = state.notifications.copyWith(
      ntfyTopic: topic,
      enabled: true,
    );
    await updateNotifications(updated);
  }
}
