import 'dart:ui';

import 'package:arrmate/core/l10n/app_locale.dart';
import 'package:arrmate/presentation/providers/locale_provider.dart';
import 'package:arrmate/presentation/providers/settings_provider.dart';
import 'package:arrmate/presentation/widgets/language_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/localized_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpPrompt(
    WidgetTester tester, {
    required bool pending,
    List<Locale> deviceLocales = const [Locale('es', 'MX')],
  }) async {
    final container = ProviderContainer(
      overrides: [
        languagePromptPendingProvider.overrideWith((ref) => pending),
        deviceLocalesProvider.overrideWithValue(deviceLocales),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    LanguagePickerDialog.showIfNeeded(context, ref),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('is skipped when the prompt is not pending', (tester) async {
    await pumpPrompt(tester, pending: false);

    expect(find.byType(LanguagePickerDialog), findsNothing);
  });

  testWidgets('preselects and previews the device language', (tester) async {
    await pumpPrompt(tester, pending: true);

    expect(find.text('Elige tu idioma'), findsOneWidget);
    final selected = tester.widget<RadioGroup<AppLanguage>>(
      find.byType(RadioGroup<AppLanguage>),
    );
    expect(selected.groupValue, AppLanguage.es);
  });

  testWidgets('switches the preview and persists the confirmed choice', (
    tester,
  ) async {
    final container = await pumpPrompt(tester, pending: true);

    await tester.tap(find.text('Português (Brasil)'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha seu idioma'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language_continue')));
    await tester.pumpAndSettle();

    expect(find.byType(LanguagePickerDialog), findsNothing);
    expect(container.read(settingsProvider).language, AppLanguage.ptBR);
    expect(container.read(languagePromptPendingProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(appLocalePreferenceKey), 'ptBR');
  });
}
