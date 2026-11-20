import 'package:arrmate/presentation/providers/settings_provider.dart';
import 'package:arrmate/presentation/screens/settings/system_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/localized_app.dart';

void main() {
  testWidgets('should group system controls on a dedicated screen', (
    tester,
  ) async {
    const screen = SystemManagementScreen();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWith(_TestSettingsNotifier.new)],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: screen,
        ),
      ),
    );

    expect(find.text('System Management'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('Torrent Protection'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Minimum seeding days'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('App Maintenance'), 200);

    expect(find.text('App Maintenance'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Reset app settings'), 200);

    expect(find.text('Reset app settings'), findsOneWidget);
    expect(find.text('Assistant'), findsNothing);
  });

  group('minimum seeding days dialog', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// Pumps the screen, opens the dialog, types [days] and taps Save.
    Future<void> saveDays(WidgetTester tester, String days) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [settingsProvider.overrideWith(_TestSettingsNotifier.new)],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: SystemManagementScreen(),
          ),
        ),
      );
      await tester.tap(find.text('Minimum seeding days'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), days);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('should disable the seeding warning when 0 is saved', (
      tester,
    ) async {
      // When
      await saveDays(tester, '0');

      // Then
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Seeding warning disabled'), findsOneWidget);
      expect(find.text('0d'), findsOneWidget);
    });

    for (final days in ['61', '-1']) {
      testWidgets('should refuse $days and keep the current value', (
        tester,
      ) async {
        // When
        await saveDays(tester, days);

        // Then
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Enter a valid number (0 to 60)'), findsOneWidget);
        expect(find.text('20d'), findsOneWidget);
      });
    }
  });
}

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}
