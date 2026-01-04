import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../../domain/models/settings/notification_settings.dart';
import '../../core/services/background_sync_service.dart';
import 'dart:convert';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final AppColorScheme colorScheme;
  final AppAppearance appearance;
  final bool isGridViewCompact;
  final NotificationSettings notifications;

  const SettingsState({
    this.colorScheme = AppColorScheme.blue,
    this.appearance = AppAppearance.system,
    this.isGridViewCompact = false,
    this.notifications = const NotificationSettings(),
  });

  SettingsState copyWith({
    AppColorScheme? colorScheme,
    AppAppearance? appearance,
    bool? isGridViewCompact,
    NotificationSettings? notifications,
  }) {
    return SettingsState(
      colorScheme: colorScheme ?? this.colorScheme,
      appearance: appearance ?? this.appearance,
      isGridViewCompact: isGridViewCompact ?? this.isGridViewCompact,
      notifications: notifications ?? this.notifications,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _colorSchemeKey = 'color_scheme';
  static const _appearanceKey = 'appearance';
  static const _gridViewKey = 'grid_view_compact';
  static const _notificationsKey = 'notification_settings';

  @override
  SettingsState build() {
    // Carregamento inicial síncrono ou estado padrão.
    // O carregamento assíncrono será feito separadamente para não bloquear a UI inicial
    // ou podemos usar AsyncNotifier se quisermos lidar com o estado de loading.
    // Por enquanto, iniciamos com default e carregamos em background.
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final colorSchemeName = prefs.getString(_colorSchemeKey);
    final appearanceName = prefs.getString(_appearanceKey);
    final isCompact = prefs.getBool(_gridViewKey);
    final notificationsJson = prefs.getString(_notificationsKey);

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
      isGridViewCompact: isCompact,
      notifications: notificationsJson != null
          ? NotificationSettings.fromJson(jsonDecode(notificationsJson))
          : const NotificationSettings(),
    );

    // Ensure background task matches settings
    if (state.notifications.enabled) {
      ref
          .read(backgroundSyncServiceProvider)
          .registerTask(state.notifications.pollingIntervalMinutes);
    }
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorSchemeKey, scheme.name);
  }

  Future<void> setAppearance(AppAppearance appearance) async {
    state = state.copyWith(appearance: appearance);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKey, appearance.name);
  }

  Future<void> setGridViewCompact(bool isCompact) async {
    state = state.copyWith(isGridViewCompact: isCompact);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridViewKey, isCompact);
  }

  Future<void> updateNotifications(NotificationSettings notifications) async {
    state = state.copyWith(notifications: notifications);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationsKey,
      jsonEncode(notifications.toJson()),
    );

    final syncService = ref.read(backgroundSyncServiceProvider);
    if (notifications.enabled) {
      await syncService.registerTask(notifications.pollingIntervalMinutes);
    } else {
      await syncService.cancelAll();
    }
  }
}
