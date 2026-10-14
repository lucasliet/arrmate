import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/repositories.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:arrmate/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockInstanceRepository extends Mock implements InstanceRepository {}

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

  testWidgets('flagsExpiredJellyfinSessionInInstanceList', (tester) async {
    final jellyfin = Instance(
      id: 'jellyfin-home',
      type: InstanceType.jellyfin,
      label: 'Home',
      url: 'https://jellyfin.example.com',
    );

    await _pumpSettings(
      tester,
      PlatformCapabilities.forPlatform(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
      overrides: [
        instancesProvider.overrideWith(
          () => _FakeInstancesNotifier(
            InstancesState(instances: [jellyfin], isLoading: false),
          ),
        ),
        jellyfinSessionExpiredProvider.overrideWith(
          _FakeExpiredSessionsNotifier.new,
        ),
      ],
    );

    expect(find.text('Session expired · tap to sign in'), findsOneWidget);
    expect(find.text('https://jellyfin.example.com'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('flagsJellyfinSessionRejectedWhenSettingsOpens', (tester) async {
    final jellyfin = Instance(
      id: 'jellyfin-home',
      type: InstanceType.jellyfin,
      label: 'Home',
      url: 'https://jellyfin.example.com',
      userSession: const InstanceUserSession(
        accessToken: 'session-token',
        deviceId: 'arrmate-device',
        isAdministrator: true,
        deviceTag: 'a1b2c3d4',
      ),
    );
    final instanceRepository = _MockInstanceRepository();
    when(() => instanceRepository.getSystemStatus(jellyfin)).thenThrow(
      const UnauthorizedError(
        'Your Jellyfin session has expired. Sign in again in the instance '
        'settings (API Key field as username:password).',
      ),
    );

    await _pumpSettings(
      tester,
      PlatformCapabilities.forPlatform(
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      ),
      overrides: [
        instancesProvider.overrideWith(
          () => _FakeInstancesNotifier(
            InstancesState(instances: [jellyfin], isLoading: false),
          ),
        ),
        instanceRepositoryProvider.overrideWithValue(instanceRepository),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Session expired · tap to sign in'), findsOneWidget);
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

/// Serves a fixed instance list without touching SharedPreferences.
class _FakeInstancesNotifier extends InstancesNotifier {
  _FakeInstancesNotifier(this._state);

  final InstancesState _state;

  @override
  InstancesState build() => _state;
}

/// Starts with the Jellyfin instance `jellyfin-home` flagged as expired.
class _FakeExpiredSessionsNotifier extends JellyfinSessionExpiredNotifier {
  @override
  Set<String> build() => {'jellyfin-home'};
}

Future<void> _pumpSettings(
  WidgetTester tester,
  PlatformCapabilities capabilities, {
  List<Override> overrides = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        ...overrides,
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
