import 'dart:ui';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

/// Languages the user can pick for the app interface.
///
/// [system] follows the device language and falls back to English when the
/// device language is not one of the supported translations.
enum AppLanguage {
  /// Follows the device language.
  system(null),

  /// English.
  en(Locale('en')),

  /// Brazilian Portuguese.
  ptBR(Locale('pt', 'BR')),

  /// Spanish.
  es(Locale('es'));

  const AppLanguage(this.locale);

  /// The explicit locale for this language, or `null` for [system].
  final Locale? locale;

  /// The languages that map to an explicit translation (everything but
  /// [system]).
  static List<AppLanguage> get explicit =>
      values.where((language) => language != system).toList();

  /// The value persisted in SharedPreferences.
  String get storageValue => name;

  /// The language name written in the language itself, so it stays
  /// recognizable whatever the current interface language is.
  ///
  /// Returns `null` for [system], whose label must come from the current
  /// translation.
  String? get nativeName => switch (this) {
    AppLanguage.system => null,
    AppLanguage.en => 'English',
    AppLanguage.ptBR => 'Português (Brasil)',
    AppLanguage.es => 'Español',
  };

  /// Parses a persisted [storageValue], returning [system] when [value] is
  /// missing or unknown.
  static AppLanguage fromStorage(String? value) {
    if (value == null) return AppLanguage.system;
    return AppLanguage.values.firstWhere(
      (language) => language.storageValue == value,
      orElse: () => AppLanguage.system,
    );
  }

  /// Picks the explicit language that best matches [deviceLocales], falling
  /// back to [en].
  ///
  /// Any Portuguese variant maps to [ptBR], the only Portuguese translation.
  static AppLanguage fromDeviceLocales(List<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      switch (locale.languageCode) {
        case 'en':
          return AppLanguage.en;
        case 'pt':
          return AppLanguage.ptBR;
        case 'es':
          return AppLanguage.es;
      }
    }
    return AppLanguage.en;
  }
}

/// Resolves the [Locale] the interface must use for [language].
///
/// Explicit languages map to their own locale; [AppLanguage.system] maps to
/// the first supported entry of [deviceLocales], or English.
Locale resolveAppLocale(AppLanguage language, List<Locale> deviceLocales) {
  return (language.locale ??
      AppLanguage.fromDeviceLocales(deviceLocales).locale)!;
}

/// Returns the [AppLocalizations] for [locale] without a [BuildContext].
///
/// Used by services and providers that build user-facing text outside the
/// widget tree.
AppLocalizations appLocalizationsFor(Locale locale) {
  return lookupAppLocalizations(locale);
}

/// Returns the `intl` locale name (for example `pt_BR`) used for
/// `Intl.defaultLocale` and `timeago`.
String intlLocaleName(Locale locale) {
  final country = locale.countryCode;
  if (country == null || country.isEmpty) return locale.languageCode;
  return '${locale.languageCode}_$country';
}
