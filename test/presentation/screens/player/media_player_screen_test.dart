import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/presentation/screens/player/media_player_screen.dart';
import 'package:arrmate/presentation/screens/player/playback_request.dart';
import 'package:arrmate/presentation/screens/player/playback_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'playback_session_controller_test.dart' show FakeStreamPlayer;
import '../../../helpers/localized_app.dart';

const _fallbackMessage = 'In-app playback is not supported on the web yet';
const _externalUnavailableMessage =
    'Opening this media in an external player is not available for the '
    'current server configuration.';

const _webCapabilities = PlatformCapabilities(
  isWeb: true,
  supportsAppUpdates: false,
  supportsBackgroundNotifications: false,
  localAssistantRuntime: LocalAssistantRuntime.none,
  supportsFileSystemCache: false,
  supportsBrowserFileInput: true,
  supportsInternalVideoPlayer: false,
);

const _nativeCapabilities = PlatformCapabilities(
  isWeb: false,
  supportsAppUpdates: true,
  supportsBackgroundNotifications: true,
  localAssistantRuntime: LocalAssistantRuntime.liteRt,
  supportsFileSystemCache: true,
  supportsBrowserFileInput: false,
  supportsInternalVideoPlayer: true,
);

const MethodChannel _launchChannel = MethodChannel(
  'plugins.flutter.io/url_launcher',
);

/// Records every url_launcher platform-channel call and reports
/// [canLaunchResult] for `canLaunch`/`launch`, so tests never touch real
/// platform channels.
List<MethodCall> _mockUrlLauncher(WidgetTester tester, bool canLaunchResult) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _launchChannel,
    (call) async {
      calls.add(call);
      if (call.method == 'canLaunch' || call.method == 'launch') {
        return canLaunchResult;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _launchChannel,
      null,
    ),
  );
  return calls;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required PlaybackRequest request,
  required PlatformCapabilities capabilities,
  StreamPlayer Function()? playerFactory,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [platformCapabilitiesProvider.overrideWithValue(capabilities)],
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        locale: testLocale,
        home: MediaPlayerScreen(request: request, playerFactory: playerFactory),
      ),
    ),
  );
}

PlaybackRequest _request({String? externalUrl}) {
  return PlaybackRequest(
    title: 'Fallback Movie',
    // The stream URL carries an ApiKey and must never be offered externally.
    streamUrl: Uri.parse('http://server.example/Videos/1/stream?ApiKey=K'),
    externalUrl: externalUrl,
  );
}

void main() {
  testWidgets(
    'web fallback explains unavailability when external launching is not allowed',
    (tester) async {
      // Given
      final launchCalls = _mockUrlLauncher(tester, true);
      // externalUrl is null (API-key mode): external launching is not allowed.
      final request = _request();

      // When
      await _pumpScreen(
        tester,
        request: request,
        capabilities: _webCapabilities,
      );
      await tester.pump();

      // Then
      expect(find.text(_fallbackMessage), findsOneWidget);
      expect(find.text(_externalUnavailableMessage), findsOneWidget);
      expect(find.text('Open externally'), findsNothing);
      // The launchability probe must not even run without an externalUrl.
      expect(launchCalls, isEmpty);
    },
  );

  testWidgets(
    'web fallback offers the external action when the request has an externalUrl',
    (tester) async {
      // Given
      final launchCalls = _mockUrlLauncher(tester, true);
      const externalUrl = 'http://server.example/web/itemDetails?id=1';
      final request = _request(externalUrl: externalUrl);

      // When
      await _pumpScreen(
        tester,
        request: request,
        capabilities: _webCapabilities,
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text(_fallbackMessage), findsOneWidget);
      expect(find.text('Open externally'), findsOneWidget);
      // The probe targets the external URL, never the ApiKey stream URL.
      expect(launchCalls, hasLength(1));
      expect(launchCalls.single.method, 'canLaunch');
      expect(launchCalls.single.arguments['url'], externalUrl);
    },
  );

  testWidgets(
    'web fallback hides the external action when launching is unavailable',
    (tester) async {
      // Given
      final launchCalls = _mockUrlLauncher(tester, false);
      final request = _request(externalUrl: 'http://server.example/web');

      // When
      await _pumpScreen(
        tester,
        request: request,
        capabilities: _webCapabilities,
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text(_fallbackMessage), findsOneWidget);
      expect(find.text(_externalUnavailableMessage), findsOneWidget);
      expect(find.text('Open externally'), findsNothing);
      // The probe ran against the externalUrl and came back negative.
      expect(launchCalls, hasLength(1));
      expect(launchCalls.single.arguments['url'], 'http://server.example/web');
    },
  );

  testWidgets(
    'native path renders controls and no external action without externalUrl',
    (tester) async {
      // Given
      final launchCalls = _mockUrlLauncher(tester, true);
      final player = FakeStreamPlayer();
      final request = _request();

      // When
      await _pumpScreen(
        tester,
        request: request,
        capabilities: _nativeCapabilities,
        playerFactory: () => player,
      );
      await tester.pump();

      // The controls overlay renders above the (fake) video surface.
      // Then
      expect(find.text('Fallback Movie'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      // No external-launch action anywhere, and no launch probe.
      expect(find.byTooltip('Open externally'), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
      expect(launchCalls, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'native path opens the externalUrl when the external action is used',
    (tester) async {
      // Given
      final launchCalls = _mockUrlLauncher(tester, true);
      const externalUrl = 'http://server.example/web/itemDetails?id=1';
      final player = FakeStreamPlayer();
      final request = _request(externalUrl: externalUrl);

      // When
      await _pumpScreen(
        tester,
        request: request,
        capabilities: _nativeCapabilities,
        playerFactory: () => player,
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byTooltip('Open externally'), findsOneWidget);

      await tester.tap(find.byTooltip('Open externally'));
      await tester.pumpAndSettle();

      final launch = launchCalls
          .where((call) => call.method == 'launch')
          .toList();
      expect(launch, hasLength(1));
      // The stream URL (with its ApiKey) is never handed out.
      expect(launch.single.arguments['url'], externalUrl);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
