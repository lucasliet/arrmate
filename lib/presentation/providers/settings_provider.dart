import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final AppColorScheme colorScheme;
  final AppAppearance appearance;
  final bool isGridViewCompact;

  const SettingsState({
    this.colorScheme = AppColorScheme.blue,
    this.appearance = AppAppearance.system,
    this.isGridViewCompact = false,
  });

  SettingsState copyWith({
    AppColorScheme? colorScheme,
    AppAppearance? appearance,
    bool? isGridViewCompact,
  }) {
    return SettingsState(
      colorScheme: colorScheme ?? this.colorScheme,
      appearance: appearance ?? this.appearance,
      isGridViewCompact: isGridViewCompact ?? this.isGridViewCompact,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _colorSchemeKey = 'color_scheme';
  static const _appearanceKey = 'appearance';
  static const _gridViewKey = 'grid_view_compact';

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
    );
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
}
