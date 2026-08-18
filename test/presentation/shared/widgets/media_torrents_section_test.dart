import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_details_sheet.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_list_item.dart';
import 'package:arrmate/presentation/shared/providers/media_torrents_provider.dart';
import 'package:arrmate/presentation/shared/widgets/media_torrents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stand-in for the real reverse-lookup providers.
final _stubProvider = FutureProvider.autoDispose<MediaTorrents>(
  (ref) async => MediaTorrents.empty,
);

void main() {
  group('MediaTorrentsSection', () {
    testWidgets('should render one card per torrent', (tester) async {
      // Given
      await _pump(
        tester,
        MediaTorrents(
          torrents: [
            _linked(hash: 'aabb', name: 'Arrival.2016.1080p'),
            _linked(hash: 'ccdd', name: 'Dune.2021.1080p'),
          ],
        ),
      );

      // Then
      expect(find.text('Torrents'), findsOneWidget);
      expect(find.byType(TorrentListItem), findsNWidgets(2));
      expect(find.text('Arrival.2016.1080p'), findsOneWidget);
    });

    testWidgets('should stay hidden when no download client is configured', (
      tester,
    ) async {
      // Given
      await _pump(tester, MediaTorrents.skipped);

      // Then an empty list proves nothing without a client
      expect(find.text('Torrents'), findsNothing);
      expect(find.byType(TorrentListItem), findsNothing);
    });

    testWidgets('should show an empty state when nothing was found', (
      tester,
    ) async {
      // Given
      await _pump(tester, MediaTorrents.empty);

      // Then
      expect(find.text('Torrents'), findsOneWidget);
      expect(find.text('No torrents in the download client'), findsOneWidget);
    });

    testWidgets('should narrow the list down to one episode', (tester) async {
      // Given a single-episode grab and a season pack covering it
      await _pump(
        tester,
        MediaTorrents(
          torrents: [
            _linked(
              hash: 'aabb',
              name: 'Severance.S01E05',
              episodeIds: const {42},
            ),
            _linked(
              hash: 'ccdd',
              name: 'Severance.S01.1080p',
              episodeIds: const {42, 43},
            ),
            _linked(
              hash: 'eeff',
              name: 'Severance.S01E06',
              episodeIds: const {43},
            ),
          ],
        ),
        episodeId: 42,
      );

      // Then the pack shows up too, the other episode does not
      expect(find.text('Severance.S01E05'), findsOneWidget);
      expect(find.text('Severance.S01.1080p'), findsOneWidget);
      expect(find.text('Severance.S01E06'), findsNothing);
    });

    testWidgets('should open the torrent details without a library shortcut', (
      tester,
    ) async {
      // Given
      await _pump(
        tester,
        MediaTorrents(
          torrents: [_linked(hash: 'aabb', name: 'Arrival.2016.1080p')],
        ),
      );

      // When
      await tester.tap(find.byType(TorrentListItem));
      await tester.pumpAndSettle();

      // Then the user is already on the media the button would navigate to
      final sheet = tester.widget<TorrentDetailsSheet>(
        find.byType(TorrentDetailsSheet),
      );
      expect(sheet.showOpenInLibrary, isFalse);
      expect(sheet.torrent.hash, 'aabb');
      expect(find.text('Open in library'), findsNothing);
    });
  });
}

/// Pumps the section with [media] already resolved.
Future<void> _pump(
  WidgetTester tester,
  MediaTorrents media, {
  int? episodeId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [_stubProvider.overrideWith((ref) async => media)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaTorrentsSection(
              provider: _stubProvider,
              episodeId: episodeId,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LinkedTorrent _linked({
  required String hash,
  required String name,
  Set<int> episodeIds = const {},
}) {
  return LinkedTorrent(
    torrent: Torrent(
      hash: hash,
      name: name,
      size: 1000,
      progress: 1.0,
      dlspeed: 0,
      upspeed: 0,
      eta: 0,
      ratio: 1,
      status: TorrentStatus.uploading,
      state: 'uploading',
      tags: const [],
      savePath: '/downloads',
      numSeeds: 1,
      numLeechs: 0,
      downloaded: 1000,
      uploaded: 1000,
      amountLeft: 0,
      addedOn: 1700000000,
      priority: 0,
    ),
    link: const TorrentLink(
      status: TorrentLinkStatus.linked,
      movieId: 7,
      mediaTitle: 'Arrival',
    ),
    episodeIds: episodeIds,
  );
}
