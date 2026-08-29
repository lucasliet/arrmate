import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentListItem', () {
    testWidgets('should display progress percentage correctly', (tester) async {
      // Given
      final torrent = Torrent(
        hash: 'hash',
        name: 'Test Torrent',
        size: 1000,
        progress: 0.45, // 45%
        dlspeed: 100,
        upspeed: 100,
        eta: 60,
        ratio: 1.0,
        status: TorrentStatus.downloading,
        state: 'downloading',
        tags: [],
        savePath: '/path',
        numSeeds: 10,
        numLeechs: 5,
        downloaded: 450,
        uploaded: 100,
        amountLeft: 550,
        addedOn: 1234567890,
        priority: 1,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then
      expect(find.text('45% done'), findsOneWidget);
    });

    testWidgets('should display 100% progress correctly', (tester) async {
      // Given
      final torrent = Torrent(
        hash: 'hash',
        name: 'Completed Torrent',
        size: 1000,
        progress: 1.0, // 100%
        dlspeed: 0,
        upspeed: 0,
        eta: 0,
        ratio: 2.0,
        status: TorrentStatus.uploading,
        state: 'seeding',
        tags: [],
        savePath: '/path',
        numSeeds: 0,
        numLeechs: 0,
        downloaded: 1000,
        uploaded: 2000,
        amountLeft: 0,
        addedOn: 1234567890,
        priority: 0,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then
      expect(find.text('100% done'), findsOneWidget);
    });

    testWidgets('should display 0% progress correctly', (tester) async {
      // Given
      final torrent = Torrent(
        hash: 'hash',
        name: 'New Torrent',
        size: 1000,
        progress: 0.0, // 0%
        dlspeed: 0,
        upspeed: 0,
        eta: -1,
        ratio: 0.0,
        status: TorrentStatus.downloading,
        state: 'downloading',
        tags: [],
        savePath: '/path',
        numSeeds: 0,
        numLeechs: 0,
        downloaded: 0,
        uploaded: 0,
        amountLeft: 1000,
        addedOn: 1234567890,
        priority: 1,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then
      expect(find.text('0% done'), findsOneWidget);
    });

    testWidgets('should show the linked media on the library badge', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TorrentListItem(
              torrent: torrent,
              link: const TorrentLink(
                status: TorrentLinkStatus.linked,
                seriesId: 3,
                seasonNumber: 1,
                episodeNumber: 5,
                mediaTitle: 'Severance',
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text('Severance · S01E05'), findsOneWidget);
    });

    testWidgets('should highlight an orphan torrent with an error border', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TorrentListItem(
              torrent: torrent,
              link: const TorrentLink(status: TorrentLinkStatus.orphan),
            ),
          ),
        ),
      );

      // Then
      expect(find.text('Orphan'), findsOneWidget);
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.side.style, BorderStyle.solid);
    });

    testWidgets('should not render a badge when the relation is unknown', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TorrentListItem(torrent: torrent, link: TorrentLink.unknown),
          ),
        ),
      );

      // Then
      expect(find.byKey(const ValueKey('torrent-link-badge')), findsNothing);
    });

    testWidgets('should badge a link inherited from a cross-seed sibling', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TorrentListItem(
              torrent: torrent,
              link: const TorrentLink(
                status: TorrentLinkStatus.linked,
                movieId: 7,
                mediaTitle: 'Arrival',
              ).asCrossSeed(),
            ),
          ),
        ),
      );

      // Then
      expect(find.byKey(const ValueKey('torrent-link-badge')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('torrent-cross-seed-badge')),
        findsOneWidget,
      );
      expect(find.text('Cross-seed'), findsOneWidget);
      expect(find.text('Arrival'), findsOneWidget);
    });

    testWidgets('should show how long a seeding torrent has been seeding', (
      tester,
    ) async {
      // Given a torrent seeding for 1 day and 2 hours
      final torrent = _torrent(seedingTime: 93600);

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then
      expect(find.byKey(const ValueKey('torrent-seed-time')), findsOneWidget);
      expect(find.text('1d 2h'), findsOneWidget);
    });

    testWidgets('should omit the seed time when the torrent never seeded', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then
      expect(find.byKey(const ValueKey('torrent-seed-time')), findsNothing);
    });

    testWidgets('should fit progress, seed time, speed and ETA in one row', (
      tester,
    ) async {
      // Given a torrent seeding before it went back to downloading: the details
      // row carries all four entries at once, on a narrow screen
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final torrent = _torrent(
        status: TorrentStatus.downloading,
        state: 'downloading',
        progress: 0.45,
        dlspeed: 2621440,
        eta: 5400,
        seedingTime: 93600,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TorrentListItem(torrent: torrent)),
        ),
      );

      // Then all four are rendered and the row absorbs them without overflowing
      expect(find.text('45% done'), findsOneWidget);
      expect(find.text('1d 2h'), findsOneWidget);
      expect(find.text('↓ 2.5 MB/s'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should not badge a cross-seed on a direct link', (
      tester,
    ) async {
      // Given
      final torrent = _torrent();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TorrentListItem(
              torrent: torrent,
              link: const TorrentLink(
                status: TorrentLinkStatus.linked,
                movieId: 7,
                mediaTitle: 'Arrival',
              ),
            ),
          ),
        ),
      );

      // Then
      expect(
        find.byKey(const ValueKey('torrent-cross-seed-badge')),
        findsNothing,
      );
    });
  });
}

Torrent _torrent({
  int seedingTime = 0,
  TorrentStatus status = TorrentStatus.uploading,
  String state = 'seeding',
  double progress = 1.0,
  int dlspeed = 0,
  int eta = 0,
}) {
  return Torrent(
    hash: 'hash',
    name: 'Test Torrent',
    size: 1000,
    progress: progress,
    dlspeed: dlspeed,
    upspeed: 0,
    eta: eta,
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
