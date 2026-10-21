import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/torrent_file_providers.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/localized_app.dart';

class MockQBittorrentService extends Mock implements QBittorrentService {}

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
  );
}
