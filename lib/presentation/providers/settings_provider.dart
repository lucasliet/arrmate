import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../../domain/models/settings/notification_settings.dart';
import '../../core/services/background_notification_service.dart';
import '../../core/services/ntfy_service.dart';
import '../../core/services/logger_service.dart';

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

  const SettingsState({
    this.colorScheme = AppColorScheme.blue,
    this.appearance = AppAppearance.system,
    this.viewMode = ViewMode.grid,
    this.notifications = const NotificationSettings(),
  });

  SettingsState copyWith({
    AppColorScheme? colorScheme,
    AppAppearance? appearance,
    ViewMode? viewMode,
    NotificationSettings? notifications,
  }) {
    return SettingsState(
      colorScheme: colorScheme ?? this.colorScheme,
      appearance: appearance ?? this.appearance,
      viewMode: viewMode ?? this.viewMode,
      notifications: notifications ?? this.notifications,
    );
  }
}

/// Manages user settings and persists them to SharedPreferences.
class SettingsNotifier extends Notifier<SettingsState> {
  static const _colorSchemeKey = 'color_scheme';
  static const _appearanceKey = 'appearance';
  static const viewModeKey = 'view_mode';
  static const _notificationsKey = 'notification_settings';

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

    final notifications = _parseNotificationSettings(notificationsJson);

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
    );

    if (notifications.enabled && notifications.ntfyTopic != null) {
      logger.info('[SettingsNotifier] Connecting to ntfy on startup');
      ref.read(ntfyServiceProvider).connect(notifications.ntfyTopic!);

      // Always fetch missed notifications when app opens
      BackgroundNotificationService.fetchMissedNotifications(
        notifications.ntfyTopic!,
      );

      if (!notifications.batterySaverMode) {
        logger.info('[SettingsNotifier] Starting background polling');
        BackgroundNotificationService.startPolling(
          notifications.ntfyTopic!,
          intervalMinutes: notifications.pollingIntervalMinutes,
        );
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

  /// Updates notification settings and manages the ntfy connection and background polling.
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

      if (notifications.batterySaverMode) {
        logger.info(
          '[SettingsNotifier] Battery saver mode: stopping background polling',
        );
        await BackgroundNotificationService.stopPolling();
      } else {
        logger.info('[SettingsNotifier] Starting background polling');
        await BackgroundNotificationService.startPolling(
          notifications.ntfyTopic!,
          intervalMinutes: notifications.pollingIntervalMinutes,
        );
      }
    } else {
      logger.info('[SettingsNotifier] Disabling ntfy notifications');
      await ntfyService.disconnect();
      await BackgroundNotificationService.stopPolling();
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
