import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/qbittorrent_provider.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_details_sheet.dart';
import 'package:arrmate/presentation/screens/activity/widgets/torrent_list_item.dart';
import 'package:arrmate/presentation/shared/providers/media_torrents_provider.dart';
import 'package:arrmate/presentation/shared/widgets/media_torrents_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/localized_app.dart';

/// Notifier standing in for qBittorrent: it accepts a pause at once and
/// records it, without any network or polling.
class _PauseRecordingNotifier extends QBittorrentNotifier {
  final List<String> pausedHashes = [];

  @override
  Future<List<Torrent>> build() async => const [];

  @override
  Future<void> pauseTorrents(List<String> hashes) async {
    pausedHashes.addAll(hashes);
  }
}

class _MockQBittorrentService extends Mock implements QBittorrentService {}

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

    testWidgets(
      'should reload once the client reports a pause made from the sheet',
      (tester) async {
        // Given a client that reports the pause only when asked a second
        // time, on a view tall enough to build the sheet actions
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 2400);
        addTearDown(tester.view.reset);
        final notifier = _PauseRecordingNotifier();
        var loads = 0;
        var clientReads = 0;
        final service = _MockQBittorrentService();
        when(service.getTorrents).thenAnswer((_) async {
          clientReads++;
          return [
            _linked(
              hash: 'aabb',
              name: 'Arrival.2016.1080p',
              status: clientReads >= 2
                  ? TorrentStatus.pausedUP
                  : TorrentStatus.uploading,
            ).torrent,
          ];
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              qbittorrentTorrentsProvider.overrideWith(() => notifier),
              qbittorrentServiceProvider.overrideWithValue(service),
              _stubProvider.overrideWith((ref) async {
                loads++;
                return MediaTorrents(
                  torrents: [
                    _linked(
                      hash: 'aabb',
                      name: 'Arrival.2016.1080p',
                      status: clientReads >= 2
                          ? TorrentStatus.pausedUP
                          : TorrentStatus.uploading,
                    ),
                  ],
                );
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: testSupportedLocales,
              locale: testLocale,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MediaTorrentsSection(provider: _stubProvider),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TorrentListItem));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Then
        expect(notifier.pausedHashes, ['aabb']);
        expect(clientReads, 2);
        expect(loads, 2);
        expect(
          tester
              .widget<TorrentListItem>(find.byType(TorrentListItem))
              .torrent
              .status,
          TorrentStatus.pausedUP,
        );

        // When the state is confirmed
        await tester.pump(const Duration(seconds: 5));

        // Then the client is left alone and the list is not reloaded again
        expect(clientReads, 2);
        expect(loads, 2);
      },
    );
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
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        locale: testLocale,
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
  TorrentStatus status = TorrentStatus.uploading,
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
      status: status,
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
