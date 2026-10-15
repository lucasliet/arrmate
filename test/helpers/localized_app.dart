import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:flutter/widgets.dart';

/// Localization delegates widget tests pass to their `MaterialApp`.
const testLocalizationsDelegates = AppLocalizations.localizationsDelegates;

/// Locales the app supports, for widget tests building a `MaterialApp`.
const testSupportedLocales = AppLocalizations.supportedLocales;

/// Locale widget tests run in, so text assertions match the English copy.
const testLocale = Locale('en');
