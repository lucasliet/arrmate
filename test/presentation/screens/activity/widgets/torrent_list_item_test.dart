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
  });
}

Torrent _torrent() {
  return Torrent(
    hash: 'hash',
    name: 'Test Torrent',
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1.0,
    status: TorrentStatus.uploading,
    state: 'seeding',
    tags: [],
    savePath: '/path',
    numSeeds: 1,
    numLeechs: 1,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: 1234567890,
    priority: 0,
  );
}
