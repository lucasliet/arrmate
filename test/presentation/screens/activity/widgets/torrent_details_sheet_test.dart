import 'dart:async';

import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/services/torrent_file_export_service.dart';
import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/torrent_file_providers.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/localized_app.dart';

class MockQBittorrentService extends Mock implements QBittorrentService {}

class _FakeTorrentFileExportService extends TorrentFileExportService {
  _FakeTorrentFileExportService({this.aborted = false});

  final bool aborted;
  String? savedName;
  Uint8List? savedBytes;

  @override
  Future<String?> saveTorrentFile(String torrentName, Uint8List bytes) async {
    if (aborted) return null;
    savedName = torrentName;
    savedBytes = bytes;
    return TorrentFileExportService.buildFileName(torrentName);
  }
}

void main() {
  group('TorrentDetailsSheet', () {
    testWidgets('should show the elapsed seed time of a seeding torrent', (
      tester,
    ) async {
      // Given a torrent seeding for 3 days and 4 hours
      await _pump(tester, _torrent(seedingTime: 273600));

      // Then
      expect(
        find.byKey(const ValueKey('torrent-seed-time-stat')),
        findsOneWidget,
      );
      expect(find.text('Seed Time'), findsOneWidget);
      expect(find.text('3d 4h'), findsOneWidget);
    });

    testWidgets('should open the trackers sheet from the details actions', (
      tester,
    ) async {
      await _pump(
        tester,
        _torrent(),
        overrides: [
          qbittorrentServiceProvider.overrideWithValue(null),
          torrentTrackersProvider.overrideWith(
            (ref, hash) async => [
              TorrentTracker(
                url: 'https://tracker.example/announce',
                status: TorrentTrackerStatus.working,
                tier: 0,
                numPeers: 4,
                numSeeds: 3,
                numLeeches: 1,
                numDownloaded: 0,
              ),
            ],
          ),
        ],
      );

      await tester.scrollUntilVisible(find.text('Trackers'), 200);
      await tester.tap(find.byKey(const ValueKey('torrent-trackers-button')));
      await tester.pumpAndSettle();

      expect(find.text('tracker.example'), findsOneWidget);
      expect(find.text('Working'), findsOneWidget);
      expect(find.text('3 seeds · 1 leecher · 4 peers'), findsOneWidget);
    });

    group('sharing the torrent', () {
      const magnet = 'magnet:?xt=urn:btih:hash&dn=Test%20Torrent';
      late MockQBittorrentService service;

      setUp(() {
        service = MockQBittorrentService();
      });

      Future<void> pumpSharing(
        WidgetTester tester,
        Torrent torrent,
        TorrentFileExportService exporter,
      ) {
        return _pump(
          tester,
          torrent,
          overrides: [
            qbittorrentServiceProvider.overrideWithValue(service),
            torrentFileExportServiceProvider.overrideWithValue(exporter),
          ],
        );
      }

      Future<void> tapAction(WidgetTester tester, String key) async {
        final button = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(button, 200);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      testWidgets('should copy the magnet link to the clipboard', (
        tester,
      ) async {
        // Given
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await pumpSharing(
          tester,
          _torrent(magnetUri: magnet),
          _FakeTorrentFileExportService(),
        );

        // When
        await tapAction(tester, 'torrent-copy-magnet-button');

        // Then
        expect(copied, magnet);
        expect(find.text('Magnet link copied'), findsOneWidget);
      });

      testWidgets('should disable the copy when there is no magnet link', (
        tester,
      ) async {
        // Given
        await pumpSharing(tester, _torrent(), _FakeTorrentFileExportService());

        // When
        final button = find.byKey(const ValueKey('torrent-copy-magnet-button'));
        await tester.scrollUntilVisible(button, 200);

        // Then
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      });

      testWidgets('should save the torrent file the server exported', (
        tester,
      ) async {
        // Given
        final bytes = Uint8List.fromList([100, 101]);
        when(
          () => service.exportTorrent('hash'),
        ).thenAnswer((_) async => bytes);
        final exporter = _FakeTorrentFileExportService();
        await pumpSharing(tester, _torrent(), exporter);

        // When
        await tapAction(tester, 'torrent-export-file-button');

        // Then
        expect(exporter.savedName, 'Test Torrent');
        expect(exporter.savedBytes, bytes);
        expect(find.text('Torrent file exported'), findsOneWidget);
      });

      testWidgets('should stay silent when the save dialog is dismissed', (
        tester,
      ) async {
        // Given
        when(
          () => service.exportTorrent('hash'),
        ).thenAnswer((_) async => Uint8List(0));
        await pumpSharing(
          tester,
          _torrent(),
          _FakeTorrentFileExportService(aborted: true),
        );

        // When
        await tapAction(tester, 'torrent-export-file-button');

        // Then
        expect(find.text('Torrent file exported'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('should say why the export failed', (tester) async {
        // Given a server without the export endpoint
        final request = RequestOptions(path: '/api/v2/torrents/export');
        when(() => service.exportTorrent('hash')).thenAnswer(
          (_) => Future.error(
            DioException.badResponse(
              statusCode: 404,
              requestOptions: request,
              response: Response<dynamic>(
                requestOptions: request,
                statusCode: 404,
              ),
            ),
          ),
        );
        final exporter = _FakeTorrentFileExportService();
        await pumpSharing(tester, _torrent(), exporter);

        // When
        await tapAction(tester, 'torrent-export-file-button');

        // Then
        expect(exporter.savedBytes, isNull);
        expect(
          find.textContaining('The torrent action failed'),
          findsOneWidget,
        );
      });

      testWidgets(
        'should keep the route underneath when the sheet closes mid-export',
        (tester) async {
          // Given the sheet open over a pushed route and a slow server
          final pending = Completer<Uint8List>();
          when(
            () => service.exportTorrent('hash'),
          ).thenAnswer((_) => pending.future);
          final exporter = _FakeTorrentFileExportService();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                qbittorrentServiceProvider.overrideWithValue(service),
                torrentFileExportServiceProvider.overrideWithValue(exporter),
              ],
              child: MaterialApp(
                localizationsDelegates: testLocalizationsDelegates,
                supportedLocales: testSupportedLocales,
                locale: testLocale,
                home: const Scaffold(body: Text('Root')),
              ),
            ),
          );
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator),
          );
          navigator.push(
            MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TorrentDetailsSheet(torrent: _torrent()),
                  ),
                  child: const Text('Underneath'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Underneath'));
          await tester.pumpAndSettle();
          final button = find.byKey(
            const ValueKey('torrent-export-file-button'),
          );
          await tester.scrollUntilVisible(button, 200);
          await tester.tap(button);
          await tester.pump();

          // When the sheet is dismissed before the server answers
          navigator.pop();
          await tester.pumpAndSettle();
          pending.complete(Uint8List.fromList([1]));
          await tester.pumpAndSettle();

          // Then
          expect(find.text('Underneath'), findsOneWidget);
          expect(exporter.savedBytes, isNull);
        },
      );
    });

    group('actions the server refuses', () {
      late MockQBittorrentService service;

      setUp(() {
        service = MockQBittorrentService();
        when(service.getTorrents).thenAnswer((_) async => []);
        when(service.allowAuthenticationRetry).thenReturn(null);
      });

      Future<void> pumpWithService(WidgetTester tester, Torrent torrent) {
        return _pump(
          tester,
          torrent,
          overrides: [qbittorrentServiceProvider.overrideWithValue(service)],
        );
      }

      DioException refusal(int status) {
        final request = RequestOptions(path: '/api/v2/torrents/action');
        return DioException.badResponse(
          statusCode: status,
          requestOptions: request,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: status,
          ),
        );
      }

      testWidgets('should say why resume failed and keep the sheet open', (
        tester,
      ) async {
        // Given a paused torrent and a server that refuses the action
        when(
          () => service.resumeTorrents(any()),
        ).thenAnswer((_) => Future.error(refusal(404)));
        await pumpWithService(tester, _torrent());

        // When
        await tester.scrollUntilVisible(find.text('Resume'), 200);
        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        // Then the failure is shown, without the exception dump or the URL
        expect(
          find.text('The torrent action failed: Resource not found.'),
          findsOneWidget,
        );
        expect(find.textContaining('DioException'), findsNothing);
        expect(find.text('Resume'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should say why pause failed', (tester) async {
        when(
          () => service.pauseTorrents(any()),
        ).thenAnswer((_) => Future.error(refusal(500)));
        await pumpWithService(
          tester,
          _torrent(status: TorrentStatus.uploading, state: 'uploading'),
        );

        await tester.scrollUntilVisible(find.text('Pause'), 200);
        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'The torrent action failed: Server error. Please try again later.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('should say why recheck failed', (tester) async {
        when(
          () => service.recheckTorrents(any()),
        ).thenAnswer((_) => Future.error(const UnauthorizedError()));
        await pumpWithService(tester, _torrent());

        await tester.scrollUntilVisible(find.text('Recheck'), 200);
        await tester.tap(find.text('Recheck'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'The torrent action failed: Unauthorized. Please check your API '
            'key.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show nothing when the server takes the action', (
        tester,
      ) async {
        when(() => service.resumeTorrents(any())).thenAnswer((_) async {});
        await pumpWithService(tester, _torrent());

        await tester.scrollUntilVisible(find.text('Resume'), 200);
        await tester.tap(find.text('Resume'));
        await tester.pumpAndSettle();

        verify(() => service.resumeTorrents(['hash'])).called(1);
        expect(find.byType(SnackBar), findsNothing);
      });
    });

    testWidgets('should omit the seed time when the torrent never seeded', (
      tester,
    ) async {
      // Given
      await _pump(tester, _torrent());

      // Then
      expect(
        find.byKey(const ValueKey('torrent-seed-time-stat')),
        findsNothing,
      );
      expect(find.text('Seed Time'), findsNothing);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  Torrent torrent, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        locale: testLocale,
        home: Scaffold(body: TorrentDetailsSheet(torrent: torrent)),
      ),
    ),
  );
  await tester.pump();
}

Torrent _torrent({
  int seedingTime = 0,
  TorrentStatus status = TorrentStatus.pausedUP,
  String state = 'pausedUP',
  String magnetUri = '',
}) {
  return Torrent(
    hash: 'hash',
    name: 'Test Torrent',
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1.0,
    status: status,
    state: state,
    tags: [],
    savePath: '/path',
    numSeeds: 1,
    numLeechs: 1,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: 1234567890,
    priority: 0,
    seedingTime: seedingTime,
    magnetUri: magnetUri,
  );
}
