import 'package:arrmate/presentation/providers/settings_provider.dart';
import 'package:arrmate/presentation/screens/settings/system_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should group system controls on a dedicated screen', (
    tester,
  ) async {
    const screen = SystemManagementScreen();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWith(_TestSettingsNotifier.new)],
        child: const MaterialApp(home: screen),
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
}

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}
