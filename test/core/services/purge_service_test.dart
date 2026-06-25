import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:arrmate/core/services/purge_service.dart';
import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/repositories.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockQBittorrentService extends Mock implements QBittorrentService {}

PurgeService _service({
  required MockMovieRepository movieRepo,
  MockSeriesRepository? seriesRepo,
  MockQBittorrentService? qb,
}) {
  return PurgeService(
    movieRepositoryFactory: () => movieRepo,
    seriesRepositoryFactory: () => seriesRepo ?? MockSeriesRepository(),
    qbittorrentServiceFactory: () => qb,
  );
}

/// Builds a [HistoryEvent] from a minimal JSON map.
HistoryEvent _historyEvent({
  required String eventType,
  required int movieId,
  int? seriesId,
  Map<String, dynamic>? data,
}) {
  final now = DateTime(2024, 1, 1).toIso8601String();
  return HistoryEvent.fromJson({
    'id': 1,
    'eventType': eventType,
    'date': now,
    'movieId': movieId,
    if (seriesId != null) 'seriesId': seriesId,
    'quality': {
      'quality': {'id': 1, 'name': 'HD'},
    },
    if (data != null) 'data': data,
  });
}

/// Builds a [QueueItem] from a minimal JSON map.
QueueItem _queueItem({
  required int id,
  int? movieId,
  int? seriesId,
  String? downloadId,
}) {
  return QueueItem.fromJson({
    'id': id,
    if (movieId != null) 'movieId': movieId,
    if (seriesId != null) 'seriesId': seriesId,
    'title': 'Test Item',
    'protocol': 'torrent',
    'sizeleft': 0,
    'status': 'queued',
    if (downloadId != null) 'downloadId': downloadId,
  });
}

/// Builds a [Torrent] from a minimal JSON map.
Torrent _torrent({
  required String hash,
  required String name,
  String savePath = '/downloads',
}) {
  return Torrent.fromJson({
    'hash': hash,
    'name': name,
    'size': 1024,
    'progress': 1.0,
    'dlspeed': 0,
    'upspeed': 0,
    'eta': -1,
    'ratio': 1.0,
    'state': 'pausedUP',
    'save_path': savePath,
    'tags': '',
  });
}

void main() {
  group('PurgeService', () {
    test(
      'purgeMovie collects hashes from grabbed+imported history, removes queue, '
      'deletes movie with files, and deletes source torrents by hash',
      () async {
        final movieRepo = MockMovieRepository();
        final qb = MockQBittorrentService();

        final history = [
          _historyEvent(
            eventType: 'grabbed',
            movieId: 7,
            data: {'downloadId': 'HASHAAA111'},
          ),
          _historyEvent(
            eventType: 'downloadFolderImported',
            movieId: 7,
            data: {'downloadId': 'HASHAAA111'},
          ),
          // Unknown events should be ignored.
          _historyEvent(
            eventType: 'downloadIgnored',
            movieId: 7,
            data: {'downloadId': 'HASHIGNORED'},
          ),
        ];
        final queue = QueueItems(
          page: 1,
          pageSize: 20,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
          totalRecords: 1,
          records: [_queueItem(id: 50, movieId: 7, downloadId: 'HASHBBB222')],
        );

        when(
          () => movieRepo.getMovieHistory(7),
        ).thenAnswer((_) async => history);
        when(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            sortKey: any(named: 'sortKey'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((_) async => queue);
        when(
          () => movieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenAnswer((_) async {});
        when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 3);
        when(
          () => movieRepo.deleteMovie(
            any(),
            deleteFiles: any(named: 'deleteFiles'),
            addExclusion: any(named: 'addExclusion'),
          ),
        ).thenAnswer((_) async {});

        when(() => qb.getTorrents()).thenAnswer(
          (_) async => [
            _torrent(hash: 'HASHAAA111', name: 'Inception.2010.1080p.mkv'),
            _torrent(hash: 'HASHBBB222', name: 'Inception.2010.720p.mkv'),
          ],
        );
        when(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        ).thenAnswer((_) async {});

        final service = _service(movieRepo: movieRepo, qb: qb);
        final result = await service.purgeMovie(7);

        expect(result.catalogDeleted, 1);
        expect(result.queueItemsRemoved, 1);
        expect(result.mediaFilesDeleted, 3);
        expect(result.qbittorrentSkipped, false);
        expect(result.torrentHashesDeleted.length, 2);
        expect(
          result.torrentHashesDeleted,
          containsAll(['hashaaa111', 'hashbbb222']),
        );
        expect(result.crossSeedDuplicatesDeleted, isEmpty);

        verify(
          () => movieRepo.deleteQueueItem(
            50,
            removeFromClient: true,
            blocklist: false,
            skipRedownload: false,
          ),
        ).called(1);
        verify(
          () =>
              movieRepo.deleteMovie(7, deleteFiles: true, addExclusion: false),
        ).called(1);
        verify(() => qb.deleteTorrents(any(), deleteFiles: true)).called(1);
      },
    );

    test(
      'purgeMovie finds and deletes cross-seed duplicates by case-insensitive name match',
      () async {
        final movieRepo = MockMovieRepository();
        final qb = MockQBittorrentService();

        when(() => movieRepo.getMovieHistory(7)).thenAnswer(
          (_) async => [
            _historyEvent(
              eventType: 'grabbed',
              movieId: 7,
              data: {'downloadId': 'SOURCEHASH001'},
            ),
          ],
        );
        when(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            sortKey: any(named: 'sortKey'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer(
          (_) async => QueueItems(
            page: 1,
            pageSize: 20,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 0,
            records: const [],
          ),
        );
        when(
          () => movieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenAnswer((_) async {});
        when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 1);
        when(
          () => movieRepo.deleteMovie(
            any(),
            deleteFiles: any(named: 'deleteFiles'),
            addExclusion: any(named: 'addExclusion'),
          ),
        ).thenAnswer((_) async {});

        when(() => qb.getTorrents()).thenAnswer(
          (_) async => [
            // Source.
            _torrent(
              hash: 'SOURCEHASH001',
              name: 'The.Matrix.1999.1080p.BluRay.mkv',
            ),
            // Cross-seed dupe: same name, different hash, different case.
            _torrent(
              hash: 'DUPEHASH000AA',
              name: 'the.matrix.1999.1080p.bluray.mkv',
            ),
            // Not a dupe: different name.
            _torrent(hash: 'UNRELATED21', name: 'Other.Release.mkv'),
          ],
        );
        when(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        ).thenAnswer((_) async {});

        final result = await _service(
          movieRepo: movieRepo,
          qb: qb,
        ).purgeMovie(7);

        expect(result.torrentHashesDeleted, ['sourcehash001']);
        expect(result.crossSeedDuplicatesDeleted, ['dupehash000aa']);
        verify(() => qb.deleteTorrents(any(), deleteFiles: true)).called(1);
      },
    );

    test(
      'purgeMovie skips qBittorrent steps when no instance is configured',
      () async {
        final movieRepo = MockMovieRepository();
        when(() => movieRepo.getMovieHistory(7)).thenAnswer(
          (_) async => [
            _historyEvent(
              eventType: 'grabbed',
              movieId: 7,
              data: {'downloadId': 'HASHAAA111'},
            ),
          ],
        );
        when(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            sortKey: any(named: 'sortKey'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer(
          (_) async => QueueItems(
            page: 1,
            pageSize: 20,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 0,
            records: const [],
          ),
        );
        when(
          () => movieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenAnswer((_) async {});
        when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 1);
        when(
          () => movieRepo.deleteMovie(
            any(),
            deleteFiles: any(named: 'deleteFiles'),
            addExclusion: any(named: 'addExclusion'),
          ),
        ).thenAnswer((_) async {});

        final qb = MockQBittorrentService();
        when(() => qb.getTorrents()).thenAnswer((_) async => []);
        when(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        ).thenAnswer((_) async {});

        final result = await _service(
          movieRepo: movieRepo,
          qb: null,
        ).purgeMovie(7);

        expect(result.qbittorrentSkipped, true);
        expect(result.torrentHashesDeleted, isEmpty);
        expect(result.crossSeedDuplicatesDeleted, isEmpty);
        verifyNever(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        );
      },
    );

    test(
      'purgeMovie tolerates deleteQueueItem throwing and still proceeds',
      () async {
        final movieRepo = MockMovieRepository();
        final qb = MockQBittorrentService();

        when(() => movieRepo.getMovieHistory(7)).thenAnswer((_) async => []);
        when(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            sortKey: any(named: 'sortKey'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer(
          (_) async => QueueItems(
            page: 1,
            pageSize: 20,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 1,
            records: [_queueItem(id: 99, movieId: 7, downloadId: 'HASHXYZ000')],
          ),
        );
        when(
          () => movieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenThrow(Exception('already gone'));
        when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 0);
        when(
          () => movieRepo.deleteMovie(
            any(),
            deleteFiles: any(named: 'deleteFiles'),
            addExclusion: any(named: 'addExclusion'),
          ),
        ).thenAnswer((_) async {});
        when(() => qb.getTorrents()).thenAnswer(
          (_) async => [_torrent(hash: 'HASHXYZ000', name: 'release.mkv')],
        );
        when(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        ).thenAnswer((_) async {});

        final result = await _service(
          movieRepo: movieRepo,
          qb: qb,
        ).purgeMovie(7);

        expect(result.queueItemsRemoved, 0);
        expect(result.catalogDeleted, 1);
        expect(result.torrentHashesDeleted, ['hashxyz000']);
      },
    );

    test('purgeSeries collects hashes across multiple episodes and deletes all '
        'source torrents', () async {
      final seriesRepo = MockSeriesRepository();
      final qb = MockQBittorrentService();

      when(() => seriesRepo.getSeriesHistory(42)).thenAnswer(
        (_) async => [
          _historyEvent(
            eventType: 'grabbed',
            movieId: 0,
            seriesId: 42,
            data: {'downloadId': 'EP1HASH0AAA'},
          ),
          _historyEvent(
            eventType: 'seriesFolderImported',
            movieId: 0,
            seriesId: 42,
            data: {'downloadId': 'EP1HASH0AAA'},
          ),
          _historyEvent(
            eventType: 'grabbed',
            movieId: 0,
            seriesId: 42,
            data: {'downloadId': 'EP2HASH0BBB'},
          ),
          _historyEvent(
            eventType: 'seriesFolderImported',
            movieId: 0,
            seriesId: 42,
            data: {'downloadId': 'EP3HASH0CCC'},
          ),
        ],
      );
      when(
        () => seriesRepo.getQueue(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          sortKey: any(named: 'sortKey'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer(
        (_) async => QueueItems(
          page: 1,
          pageSize: 20,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
          totalRecords: 1,
          records: [
            _queueItem(id: 12, seriesId: 42, downloadId: 'EP4PENDINGHASH'),
          ],
        ),
      );
      when(
        () => seriesRepo.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => seriesRepo.deleteSeriesFiles(
          42,
          seasonNumber: any(named: 'seasonNumber'),
        ),
      ).thenAnswer((_) async => 10);
      when(
        () => seriesRepo.deleteSeries(
          any(),
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenAnswer((_) async {});

      when(() => qb.getTorrents()).thenAnswer(
        (_) async => [
          _torrent(hash: 'EP1HASH0AAA', name: 'Show.S01E01.mkv'),
          _torrent(hash: 'EP2HASH0BBB', name: 'Show.S01E02.mkv'),
          _torrent(hash: 'EP3HASH0CCC', name: 'Show.S01E03.mkv'),
          _torrent(hash: 'EP4PENDINGHASH', name: 'Show.S01E04.mkv'),
        ],
      );
      when(
        () => qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
      ).thenAnswer((_) async {});

      final result = await _service(
        movieRepo: MockMovieRepository(),
        seriesRepo: seriesRepo,
        qb: qb,
      ).purgeSeries(42);

      expect(result.catalogDeleted, 1);
      expect(result.mediaFilesDeleted, 10);
      expect(result.queueItemsRemoved, 1);
      expect(result.torrentHashesDeleted.length, 4);
      expect(
        result.torrentHashesDeleted,
        containsAll([
          'ep1hash0aaa',
          'ep2hash0bbb',
          'ep3hash0ccc',
          'ep4pendinghash',
        ]),
      );
    });

    test('purgeMovie dedupes the same hash appearing in history and queue '
        '(single torrent delete call)', () async {
      final movieRepo = MockMovieRepository();
      final qb = MockQBittorrentService();

      when(() => movieRepo.getMovieHistory(7)).thenAnswer(
        (_) async => [
          _historyEvent(
            eventType: 'grabbed',
            movieId: 7,
            data: {'downloadId': 'SHAAREDHASH'},
          ),
          _historyEvent(
            eventType: 'downloadFolderImported',
            movieId: 7,
            data: {'downloadId': 'SHAAREDHASH'},
          ),
        ],
      );
      when(
        () => movieRepo.getQueue(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          sortKey: any(named: 'sortKey'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer(
        (_) async => QueueItems(
          page: 1,
          pageSize: 20,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
          totalRecords: 1,
          records: [_queueItem(id: 3, movieId: 7, downloadId: 'SHAAREDHASH')],
        ),
      );
      when(
        () => movieRepo.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});
      when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 1);
      when(
        () => movieRepo.deleteMovie(
          any(),
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenAnswer((_) async {});

      when(() => qb.getTorrents()).thenAnswer(
        (_) async => [_torrent(hash: 'SHAAREDHASH', name: 'Inception.mkv')],
      );
      when(
        () => qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
      ).thenAnswer((_) async {});

      final result = await _service(movieRepo: movieRepo, qb: qb).purgeMovie(7);

      expect(result.torrentHashesDeleted, ['shaaredhash']);
      expect(result.crossSeedDuplicatesDeleted, isEmpty);

      // Single delete call even though the hash was seen in grabbed,
      // imported, and queue.
      verify(() => qb.deleteTorrents(any(), deleteFiles: true)).called(1);
    });

    test(
      'purgeMovie pages through the queue when items span multiple pages',
      () async {
        final movieRepo = MockMovieRepository();
        final qb = MockQBittorrentService();

        when(() => movieRepo.getMovieHistory(7)).thenAnswer((_) async => []);

        // Two pages: first page is full (pageSize=100), second page is the
        // last with our target item.
        when(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            sortKey: any(named: 'sortKey'),
            sortDirection: any(named: 'sortDirection'),
          ),
        ).thenAnswer((inv) async {
          final page = inv.namedArguments[#page] as int;
          if (page == 1) {
            return QueueItems(
              page: 1,
              pageSize: 100,
              sortKey: 'timeleft',
              sortDirection: 'ascending',
              totalRecords: 101,
              records: List.generate(
                100,
                (_) => _queueItem(id: 0, movieId: 999, downloadId: 'OTHER'),
              ),
            );
          }
          return QueueItems(
            page: 2,
            pageSize: 100,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 101,
            records: [_queueItem(id: 88, movieId: 7, downloadId: 'PAGEDHASH')],
          );
        });
        when(
          () => movieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenAnswer((_) async {});
        when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 0);
        when(
          () => movieRepo.deleteMovie(
            any(),
            deleteFiles: any(named: 'deleteFiles'),
            addExclusion: any(named: 'addExclusion'),
          ),
        ).thenAnswer((_) async {});

        when(() => qb.getTorrents()).thenAnswer(
          (_) async => [_torrent(hash: 'PAGEDHASH', name: 'release.mkv')],
        );
        when(
          () =>
              qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
        ).thenAnswer((_) async {});

        final result = await _service(
          movieRepo: movieRepo,
          qb: qb,
        ).purgeMovie(7);

        // The item on page 2 was collected, its torrent deleted and queue
        // removal called exactly for id 88.
        expect(result.queueItemsRemoved, 1);
        expect(result.torrentHashesDeleted, ['pagedhash']);
        verify(
          () => movieRepo.deleteQueueItem(
            88,
            removeFromClient: true,
            blocklist: false,
            skipRedownload: false,
          ),
        ).called(1);
      },
    );

    test('purgeMovie ignores cross-seed candidates with matching name but '
        'different savePath', () async {
      final movieRepo = MockMovieRepository();
      final qb = MockQBittorrentService();

      when(() => movieRepo.getMovieHistory(7)).thenAnswer(
        (_) async => [
          _historyEvent(
            eventType: 'grabbed',
            movieId: 7,
            data: {'downloadId': 'SOURCEHASH001'},
          ),
        ],
      );
      when(
        () => movieRepo.getQueue(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          sortKey: any(named: 'sortKey'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer(
        (_) async => QueueItems(
          page: 1,
          pageSize: 100,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
          totalRecords: 0,
          records: const [],
        ),
      );
      when(
        () => movieRepo.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});
      when(() => movieRepo.deleteMovieFiles(7)).thenAnswer((_) async => 1);
      when(
        () => movieRepo.deleteMovie(
          any(),
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenAnswer((_) async {});

      when(() => qb.getTorrents()).thenAnswer(
        (_) async => [
          _torrent(
            hash: 'SOURCEHASH001',
            name: 'The.Matrix.1999.1080p.BluRay.mkv',
            savePath: '/downloads/movies',
          ),
          // Same name but different savePath: must NOT be deleted.
          _torrent(
            hash: 'DUPEHASH000AA',
            name: 'the.matrix.1999.1080p.bluray.mkv',
            savePath: '/elsewhere/cross-seed',
          ),
          // Same name AND same savePath: real cross-seed dupe, delete it.
          _torrent(
            hash: 'REALDUPE0000',
            name: 'THE.MATRIX.1999.1080P.BLURAY.MKV',
            savePath: '/downloads/movies/',
          ),
        ],
      );
      when(
        () => qb.deleteTorrents(any(), deleteFiles: any(named: 'deleteFiles')),
      ).thenAnswer((_) async {});

      final result = await _service(movieRepo: movieRepo, qb: qb).purgeMovie(7);

      expect(result.torrentHashesDeleted, ['sourcehash001']);
      expect(result.crossSeedDuplicatesDeleted, ['realdupe0000']);
      verify(() => qb.deleteTorrents(any(), deleteFiles: true)).called(1);
    });
  });
}
