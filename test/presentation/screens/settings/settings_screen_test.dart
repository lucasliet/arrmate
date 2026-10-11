import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shouldShowGoogleDriveSubtitle_onNative', (tester) async {
    await _pumpSettings(
      tester,
      PlatformCapabilities.forPlatform(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
    );

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Import or export a local file'), findsNothing);
  });

  testWidgets('shouldShowLocalFileSubtitle_onWeb', (tester) async {
    await _pumpSettings(
      tester,
      PlatformCapabilities.forPlatform(
        isWeb: true,
        targetPlatform: TargetPlatform.android,
      ),
    );

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Import or export a local file'), findsOneWidget);
    expect(find.text('Google Drive'), findsNothing);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  PlatformCapabilities capabilities,
) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [platformCapabilitiesProvider.overrideWithValue(capabilities)],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
