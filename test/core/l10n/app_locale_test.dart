import 'dart:ui';

import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage', () {
    test('parses stored values and falls back to system', () {
      expect(AppLanguage.fromStorage('ptBR'), AppLanguage.ptBR);
      expect(AppLanguage.fromStorage('es'), AppLanguage.es);
      expect(AppLanguage.fromStorage(null), AppLanguage.system);
      expect(AppLanguage.fromStorage('fr'), AppLanguage.system);
    });

    test('round-trips through the storage value', () {
      for (final language in AppLanguage.values) {
        expect(AppLanguage.fromStorage(language.storageValue), language);
      }
    });

    test('matches the first supported device language', () {
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('fr'), Locale('es', 'MX')]),
        AppLanguage.es,
      );
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('pt', 'PT')]),
        AppLanguage.ptBR,
      );
      expect(
        AppLanguage.fromDeviceLocales(const [Locale('de')]),
        AppLanguage.en,
      );
    });

    test('names each explicit language in the language itself', () {
      expect(AppLanguage.en.nativeName, 'English');
      expect(AppLanguage.ptBR.nativeName, 'Português (Brasil)');
      expect(AppLanguage.es.nativeName, 'Español');
      expect(AppLanguage.system.nativeName, isNull);
    });
  });

  group('resolveAppLocale', () {
    test('uses the explicit language over the device', () {
      expect(
        resolveAppLocale(AppLanguage.es, const [Locale('pt', 'BR')]),
        const Locale('es'),
      );
    });

    test('follows the device for the system language', () {
      expect(
        resolveAppLocale(AppLanguage.system, const [Locale('pt', 'BR')]),
        const Locale('pt', 'BR'),
      );
      expect(
        resolveAppLocale(AppLanguage.system, const [Locale('ja')]),
        const Locale('en'),
      );
    });
  });

  test('loads translations without a BuildContext', () {
    expect(appLocalizationsFor(const Locale('en')).commonCancel, 'Cancel');
    expect(
      appLocalizationsFor(const Locale('pt', 'BR')).commonCancel,
      'Cancelar',
    );
    expect(appLocalizationsFor(const Locale('es')).commonDelete, 'Eliminar');
  });

  test('formats intl locale names', () {
    expect(intlLocaleName(const Locale('pt', 'BR')), 'pt_BR');
    expect(intlLocaleName(const Locale('es')), 'es');
  });
}
