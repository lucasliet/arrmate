import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/torrent_file_providers.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        home: Scaffold(body: TorrentDetailsSheet(torrent: torrent)),
      ),
    ),
  );
  await tester.pump();
}

Torrent _torrent({int seedingTime = 0}) {
  return Torrent(
    hash: 'hash',
    name: 'Test Torrent',
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1.0,
    status: TorrentStatus.pausedUP,
    state: 'pausedUP',
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
