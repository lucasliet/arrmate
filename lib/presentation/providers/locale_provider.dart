import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/l10n/app_locale.dart';
import 'settings_provider.dart';

/// The locales reported by the device, in preference order.
///
/// Invalidated by the app root when the device language changes so
/// [AppLanguage.system] follows it without a restart.
final deviceLocalesProvider = Provider<List<Locale>>(
  (ref) => PlatformDispatcher.instance.locales,
);

/// The locale the interface is currently rendered in.
///
/// Resolves the language chosen in Settings against the device locales and
/// keeps `Intl.defaultLocale` and the `timeago` locale in sync, so dates and
/// relative times formatted outside the widget tree match the interface.
final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(settingsProvider.select((s) => s.language));
  final locale = resolveAppLocale(language, ref.watch(deviceLocalesProvider));
  applyIntlLocale(locale);
  return locale;
});

/// The translations for [currentLocaleProvider], for code that builds
/// user-facing text without a [BuildContext].
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => appLocalizationsFor(ref.watch(currentLocaleProvider)),
);

/// Whether the first-boot language prompt still has to be shown.
///
/// Overridden in `main.dart`: it is `true` only on a fresh install, before
/// the user has picked a language or finished the onboarding tour.
final languagePromptPendingProvider = StateProvider<bool>((ref) => false);

bool _timeagoRegistered = false;

/// Points `Intl.defaultLocale` and the default `timeago` locale at [locale].
void applyIntlLocale(Locale locale) {
  if (!_timeagoRegistered) {
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
    timeago.setLocaleMessages('pt_BR_short', timeago.PtBrShortMessages());
    timeago.setLocaleMessages('es', timeago.EsMessages());
    timeago.setLocaleMessages('es_short', timeago.EsShortMessages());
    _timeagoRegistered = true;
  }
  final name = intlLocaleName(locale);
  Intl.defaultLocale = name;
  timeago.setDefaultLocale(name);
}
