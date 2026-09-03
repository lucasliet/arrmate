import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/qbittorrent_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/torrent_link_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

/// Serves a fixed torrent list, bypassing the polling timer of the real
/// notifier.
class _StubQBittorrentNotifier extends QBittorrentNotifier {
  _StubQBittorrentNotifier(this.torrents);

  final List<Torrent> torrents;

  @override
  Future<List<Torrent>> build() async => torrents;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('torrentLinkIndexProvider', () {
    test('should link a torrent whose movie still has its file', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      final link = index.resolve(torrent);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.movieId, 12);
      expect(link.mediaTitle, 'Arrival');
      expect(link.instanceId, radarr.id);
    });

    test('should report a completed torrent whose file was deleted', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: false,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr', progress: 1.0);

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.resolve(torrent).status, TorrentLinkStatus.fileMissing);
    });

    test(
      'should keep an unfinished download linked instead of file missing',
      () async {
        // Given
        final radarr = _instance('radarr-home', InstanceType.radarr);
        final repository = MockMovieRepository();
        _stubDownloadClients(repository, categories: ['radarr']);
        _stubMovieHistory(repository, {
          1: _historyPage(
            page: 1,
            records: [
              _movieEvent(
                id: 1,
                downloadId: 'aabb',
                movieId: 12,
                title: 'Arrival',
                hasFile: false,
              ),
            ],
          ),
        });
        _stubMovieQueue(repository);
        final torrent = _torrent(
          hash: 'aabb',
          category: 'radarr',
          progress: 0.4,
        );

        // When
        final index = await _resolveIndex(
          torrents: [torrent],
          radarrInstances: [radarr],
          movieRepositories: {radarr: repository},
        );

        // Then
        expect(index.resolve(torrent).status, TorrentLinkStatus.linked);
      },
    );

    test('should link an episode from the Sonarr history', () async {
      // Given
      final sonarr = _instance('sonarr-home', InstanceType.sonarr);
      final repository = MockSeriesRepository();
      _stubDownloadClients(repository, categories: ['tv-sonarr']);
      _stubSeriesHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _episodeEvent(
              id: 1,
              downloadId: 'ccdd',
              seriesId: 3,
              seriesTitle: 'Severance',
              seasonNumber: 1,
              episodeNumber: 5,
              hasFile: true,
            ),
          ],
        ),
      });
      _stubSeriesQueue(repository);
      final torrent = _torrent(hash: 'CCDD', category: 'tv-sonarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        sonarrInstances: [sonarr],
        seriesRepositories: {sonarr: repository},
      );

      // Then
      final link = index.resolve(torrent);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.seriesId, 3);
      expect(link.displayLabel, 'Severance · S01E05');
    });

    test('should flag an *arr category without a link as orphan', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {1: _historyPage(page: 1, records: [])});
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'deadbeef', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.resolve(torrent).status, TorrentLinkStatus.orphan);
    });

    test('should flag an unmanaged torrent as external', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {1: _historyPage(page: 1, records: [])});
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'deadbeef', category: 'linux-isos');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.resolve(torrent).status, TorrentLinkStatus.external);
    });

    test('should ignore categories from non-qBittorrent clients', () async {
      // Given a Usenet client sharing a generic category name
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      when(repository.getDownloadClients).thenAnswer(
        (_) async => const [
          DownloadClientInfo(
            id: 1,
            name: 'SAB',
            implementation: 'Sabnzbd',
            enable: true,
            categories: ['movies'],
          ),
        ],
      );
      _stubMovieHistory(repository, {1: _historyPage(page: 1, records: [])});
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'deadbeef', category: 'movies');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.managedCategories, isEmpty);
      expect(index.resolve(torrent).status, TorrentLinkStatus.external);
    });

    test(
      'should degrade to unknown when the history hits the page cap',
      () async {
        // Given a history that never stops offering newer pages
        final radarr = _instance('radarr-home', InstanceType.radarr);
        final repository = MockMovieRepository();
        _stubDownloadClients(repository, categories: ['radarr']);
        when(
          () => repository.getHistory(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            eventType: any(named: 'eventType'),
            includeMovie: any(named: 'includeMovie'),
          ),
        ).thenAnswer(
          (invocation) async => _historyPage(
            page: invocation.namedArguments[#page] as int,
            totalRecords: 100000,
            records: [
              _movieEvent(
                id: 1,
                downloadId: 'unrelated',
                movieId: 12,
                title: 'Arrival',
                hasFile: true,
              ),
            ],
          ),
        );
        _stubMovieQueue(repository);
        final torrent = _torrent(hash: 'aabb', category: 'radarr');

        // When
        final index = await _resolveIndex(
          torrents: [torrent],
          radarrInstances: [radarr],
          movieRepositories: {radarr: repository},
        );

        // Then
        expect(index.truncated, isTrue);
        expect(index.canClassifyMisses, isFalse);
        expect(index.resolve(torrent).status, TorrentLinkStatus.unknown);
      },
    );

    test('should fall back to categories of linked torrents', () async {
      // Given a Radarr that does not expose its download clients
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      when(repository.getDownloadClients).thenThrow(StateError('forbidden'));
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final linked = _torrent(hash: 'aabb', category: 'radarr');
      final leftover = _torrent(hash: 'ffff', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [linked, leftover],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.managedCategories, {'radarr'});
      expect(index.resolve(leftover).status, TorrentLinkStatus.orphan);
    });

    test('should degrade to unknown when an instance fails', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      when(
        () => repository.getHistory(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          eventType: any(named: 'eventType'),
          includeMovie: any(named: 'includeMovie'),
        ),
      ).thenThrow(StateError('offline'));
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.failures.map((failure) => failure.instanceId), [radarr.id]);
      expect(index.canClassifyMisses, isFalse);
      expect(index.resolve(torrent).status, TorrentLinkStatus.unknown);
    });

    test('should stop paging once every torrent hash is resolved', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          totalRecords: 400,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      verify(
        () => repository.getHistory(
          page: 1,
          pageSize: any(named: 'pageSize'),
          eventType: HistoryEventType.grabbed,
          includeMovie: true,
        ),
      ).called(1);
      verifyNever(
        () => repository.getHistory(
          page: 2,
          pageSize: any(named: 'pageSize'),
          eventType: any(named: 'eventType'),
          includeMovie: any(named: 'includeMovie'),
        ),
      );
    });

    test('should stop paging at events older than every torrent', () async {
      // Given a torrent added well after the history events
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          totalRecords: 400,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'other',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
              date: DateTime.utc(2020, 1, 2),
            ),
            _movieEvent(
              id: 2,
              downloadId: 'another',
              movieId: 13,
              title: 'Sicario',
              hasFile: true,
              date: DateTime.utc(2020, 1, 1),
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(
        hash: 'aabb',
        category: 'radarr',
        addedOn: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
      );

      // When
      await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      verifyNever(
        () => repository.getHistory(
          page: 2,
          pageSize: any(named: 'pageSize'),
          eventType: any(named: 'eventType'),
          includeMovie: any(named: 'includeMovie'),
        ),
      );
    });

    test(
      'should promote a season pack to linked across history pages',
      () async {
        // Given a season pack whose episodes are split over two pages
        final sonarr = _instance('sonarr-home', InstanceType.sonarr);
        final repository = MockSeriesRepository();
        _stubDownloadClients(repository, categories: ['tv-sonarr']);
        _stubSeriesHistory(repository, {
          1: _historyPage(
            page: 1,
            totalRecords: 400,
            records: [
              _episodeEvent(
                id: 1,
                downloadId: 'ccdd',
                seriesId: 3,
                seriesTitle: 'Severance',
                seasonNumber: 1,
                episodeNumber: 5,
                hasFile: false,
              ),
            ],
          ),
          2: _historyPage(
            page: 2,
            totalRecords: 400,
            records: [
              _episodeEvent(
                id: 2,
                downloadId: 'ccdd',
                seriesId: 3,
                seriesTitle: 'Severance',
                seasonNumber: 1,
                episodeNumber: 6,
                hasFile: true,
              ),
            ],
          ),
        });
        _stubSeriesQueue(repository);
        final torrent = _torrent(hash: 'ccdd', category: 'tv-sonarr');

        // When
        final index = await _resolveIndex(
          torrents: [torrent],
          sonarrInstances: [sonarr],
          seriesRepositories: {sonarr: repository},
        );

        // Then
        expect(index.resolve(torrent).status, TorrentLinkStatus.linked);
      },
    );

    test('should not let the queue override a history link', () async {
      // Given a completed torrent whose movie lost its file but is queued again
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: false,
            ),
          ],
        ),
      });
      _stubMovieQueue(
        repository,
        records: [
          QueueItem(
            id: 1,
            movieId: 12,
            title: 'Arrival.2016.1080p',
            status: QueueStatus.downloading,
            downloadId: 'aabb',
            protocol: 'torrent',
            sizeleft: 10,
            languages: const [],
            customFormats: const [],
            statusMessages: const [],
          ),
        ],
      );
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      expect(index.resolve(torrent).status, TorrentLinkStatus.fileMissing);
    });

    test('should skip the queue when history resolved every hash', () async {
      // Given
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      verifyNever(
        () => repository.getQueue(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });

    test('should resolve an active download from the queue', () async {
      // Given a torrent that has no grabbed event but sits in the queue
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {1: _historyPage(page: 1, records: [])});
      _stubMovieQueue(
        repository,
        records: [
          QueueItem(
            id: 1,
            movieId: 12,
            title: 'Arrival.2016.1080p',
            status: QueueStatus.downloading,
            downloadId: 'AABB',
            protocol: 'torrent',
            sizeleft: 10,
            languages: const [],
            customFormats: const [],
            statusMessages: const [],
          ),
        ],
      );
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      final link = index.resolve(torrent);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.movieId, 12);
    });

    test('should report unknown when no *arr instance is configured', () async {
      // Given
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(torrents: [torrent]);

      // Then
      expect(index.hasInstances, isFalse);
      expect(index.resolve(torrent).status, TorrentLinkStatus.unknown);
    });
  });

  group('torrentLinkIndexProvider cross-seed', () {
    test('should inherit the link of a same-named source torrent', () async {
      // Given a grabbed torrent and a cross-seed copy of it under another hash
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final source = _torrent(
        hash: 'aabb',
        category: 'radarr',
        name: 'Arrival.2016.1080p.BluRay.mkv',
      );
      // Cross-seed: same release name in another case, different hash.
      final crossSeed = _torrent(
        hash: 'ccdd',
        category: 'radarr',
        name: 'arrival.2016.1080p.bluray.mkv ',
      );

      // When
      final index = await _resolveIndex(
        torrents: [source, crossSeed],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then the copy is linked to the same movie instead of looking orphaned
      final link = index.resolve(crossSeed);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.movieId, 12);
      expect(link.mediaTitle, 'Arrival');
      expect(link.instanceId, 'radarr-home');
      expect(link.isCrossSeed, isTrue);
      // The torrent *arr actually grabbed is not marked as a cross-seed.
      expect(index.resolve(source).isCrossSeed, isFalse);
    });

    test(
      'should inherit a fileMissing link on a complete cross-seed',
      () async {
        // Given a grabbed movie whose file was deleted
        final radarr = _instance('radarr-home', InstanceType.radarr);
        final repository = MockMovieRepository();
        _stubDownloadClients(repository, categories: ['radarr']);
        _stubMovieHistory(repository, {
          1: _historyPage(
            page: 1,
            records: [
              _movieEvent(
                id: 1,
                downloadId: 'AABB',
                movieId: 12,
                title: 'Arrival',
                hasFile: false,
              ),
            ],
          ),
        });
        _stubMovieQueue(repository);
        final source = _torrent(
          hash: 'aabb',
          name: 'Arrival.2016',
          category: 'radarr',
        );
        final crossSeed = _torrent(
          hash: 'ccdd',
          name: 'Arrival.2016',
          category: 'radarr',
        );

        // When
        final index = await _resolveIndex(
          torrents: [source, crossSeed],
          radarrInstances: [radarr],
          movieRepositories: {radarr: repository},
        );

        // Then
        final link = index.resolve(crossSeed);
        expect(link.status, TorrentLinkStatus.fileMissing);
        expect(link.isCrossSeed, isTrue);
      },
    );

    test('should report an incomplete cross-seed as linked', () async {
      // Given a deleted movie file and a cross-seed still downloading
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: false,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final source = _torrent(
        hash: 'aabb',
        name: 'Arrival.2016',
        category: 'radarr',
      );
      final crossSeed = _torrent(
        hash: 'ccdd',
        name: 'Arrival.2016',
        category: 'radarr',
        progress: 0.4,
      );

      // When
      final index = await _resolveIndex(
        torrents: [source, crossSeed],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then an unfinished download has nothing to import yet
      final link = index.resolve(crossSeed);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.isCrossSeed, isTrue);
    });

    test('should keep classifying unrelated torrents as orphan', () async {
      // Given a grabbed torrent and an unrelated one in the managed category
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final source = _torrent(
        hash: 'aabb',
        name: 'Arrival.2016',
        category: 'radarr',
      );
      final unrelated = _torrent(
        hash: 'ccdd',
        name: 'Dune.2021',
        category: 'radarr',
      );

      // When
      final index = await _resolveIndex(
        torrents: [source, unrelated],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then the name match must not swallow the orphan detection
      expect(index.resolve(unrelated).status, TorrentLinkStatus.orphan);
      expect(index.resolve(unrelated).isCrossSeed, isFalse);
    });

    test('should prefer a linked sibling over a fileMissing one', () async {
      // Given two grabs of the same release, one of which still has its file
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistory(repository, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: false,
            ),
            _movieEvent(
              id: 2,
              downloadId: 'EEFF',
              movieId: 13,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final missing = _torrent(
        hash: 'aabb',
        name: 'Arrival.2016',
        category: 'radarr',
      );
      final present = _torrent(
        hash: 'eeff',
        name: 'Arrival.2016',
        category: 'radarr',
      );
      final crossSeed = _torrent(
        hash: 'ccdd',
        name: 'Arrival.2016',
        category: 'radarr',
      );

      // When
      final index = await _resolveIndex(
        torrents: [missing, present, crossSeed],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      final link = index.resolve(crossSeed);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.movieId, 13);
      expect(link.isCrossSeed, isTrue);
    });

    test('should not inherit a link that points at no media', () async {
      // Given an instance that failed, so nothing resolved at all
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      when(
        () => repository.getHistory(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          eventType: any(named: 'eventType'),
          includeMovie: any(named: 'includeMovie'),
        ),
      ).thenThrow(Exception('boom'));
      _stubMovieQueue(repository);
      final first = _torrent(
        hash: 'aabb',
        name: 'Arrival.2016',
        category: 'radarr',
      );
      final second = _torrent(
        hash: 'ccdd',
        name: 'Arrival.2016',
        category: 'radarr',
      );

      // When
      final index = await _resolveIndex(
        torrents: [first, second],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then the name index stays empty and both stay unknown
      expect(index.linksByName, isEmpty);
      expect(index.resolve(second).status, TorrentLinkStatus.unknown);
    });

    test('should keep a movie linked once the download was imported', () async {
      // Given a torrent Radarr never grabbed: it was added to the client by
      // hand, tracked through its category, and manually imported. The queue
      // entry is gone and no grab event was ever written, so the import event
      // is the only trace of the relation left.
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistoryFor(repository, HistoryEventType.grabbed, {
        1: _historyPage(page: 1, records: const []),
      });
      _stubMovieHistoryFor(repository, HistoryEventType.imported, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              eventType: 'downloadFolderImported',
              downloadId: 'AABB',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      final index = await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      final link = index.resolve(torrent);
      expect(link.status, TorrentLinkStatus.linked);
      expect(link.movieId, 12);
      expect(link.mediaTitle, 'Arrival');
    });

    test(
      'should keep an episode linked once the download was imported',
      () async {
        // Given
        final sonarr = _instance('sonarr-home', InstanceType.sonarr);
        final repository = MockSeriesRepository();
        _stubDownloadClients(repository, categories: ['sonarr']);
        _stubSeriesHistoryFor(repository, HistoryEventType.grabbed, {
          1: _historyPage(page: 1, records: const []),
        });
        _stubSeriesHistoryFor(repository, HistoryEventType.imported, {
          1: _historyPage(
            page: 1,
            records: [
              _episodeEvent(
                id: 1,
                eventType: 'downloadFolderImported',
                downloadId: 'ccdd',
                seriesId: 5,
                seriesTitle: 'Severance',
                seasonNumber: 1,
                episodeNumber: 5,
                hasFile: true,
              ),
            ],
          ),
        });
        _stubSeriesQueue(repository);
        final torrent = _torrent(hash: 'CCDD', category: 'sonarr');

        // When
        final index = await _resolveIndex(
          torrents: [torrent],
          sonarrInstances: [sonarr],
          seriesRepositories: {sonarr: repository},
        );

        // Then
        final link = index.resolve(torrent);
        expect(link.status, TorrentLinkStatus.linked);
        expect(link.seriesId, 5);
        expect(link.episodeLabel, 'S01E05');
      },
    );

    test('should not read import events once the grabs resolved', () async {
      // Given
      // The extra sweep exists for what the grabs miss; asking for it when
      // nothing is pending would double the history traffic of every refresh.
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      _stubDownloadClients(repository, categories: ['radarr']);
      _stubMovieHistoryFor(repository, HistoryEventType.grabbed, {
        1: _historyPage(
          page: 1,
          records: [
            _movieEvent(
              id: 1,
              downloadId: 'aabb',
              movieId: 12,
              title: 'Arrival',
              hasFile: true,
            ),
          ],
        ),
      });
      _stubMovieHistoryFor(repository, HistoryEventType.imported, {
        1: _historyPage(page: 1, records: const []),
      });
      _stubMovieQueue(repository);
      final torrent = _torrent(hash: 'aabb', category: 'radarr');

      // When
      await _resolveIndex(
        torrents: [torrent],
        radarrInstances: [radarr],
        movieRepositories: {radarr: repository},
      );

      // Then
      verifyNever(
        () => repository.getHistory(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          eventType: HistoryEventType.imported,
          includeMovie: any(named: 'includeMovie'),
        ),
      );
    });
  });
}

/// Builds the index for [torrents] against the given instances.
Future<TorrentLinkIndex> _resolveIndex({
  required List<Torrent> torrents,
  List<Instance> radarrInstances = const [],
  List<Instance> sonarrInstances = const [],
  Map<Instance, MovieRepository> movieRepositories = const {},
  Map<Instance, SeriesRepository> seriesRepositories = const {},
}) async {
  final container = ProviderContainer(
    overrides: [
      qbittorrentTorrentsProvider.overrideWith(
        () => _StubQBittorrentNotifier(torrents),
      ),
      instancesByTypeProvider(
        InstanceType.radarr,
      ).overrideWithValue(radarrInstances),
      instancesByTypeProvider(
        InstanceType.sonarr,
      ).overrideWithValue(sonarrInstances),
      for (final entry in movieRepositories.entries)
        movieRepositoryForInstanceProvider(
          entry.key,
        ).overrideWithValue(entry.value),
      for (final entry in seriesRepositories.entries)
        seriesRepositoryForInstanceProvider(
          entry.key,
        ).overrideWithValue(entry.value),
    ],
  );
  addTearDown(container.dispose);

  await container.read(qbittorrentTorrentsProvider.future);
  return container.read(torrentLinkIndexProvider.future);
}

void _stubDownloadClients(
  dynamic repository, {
  List<String> categories = const [],
}) {
  when(repository.getDownloadClients).thenAnswer(
    (_) async => [
      DownloadClientInfo(
        id: 1,
        name: 'qBit',
        implementation: 'QBittorrent',
        enable: true,
        categories: categories,
      ),
    ],
  );
}

void _stubMovieHistory(
  MockMovieRepository repository,
  Map<int, HistoryPage> pages,
) {
  for (final entry in pages.entries) {
    when(
      () => repository.getHistory(
        page: entry.key,
        pageSize: any(named: 'pageSize'),
        eventType: any(named: 'eventType'),
        includeMovie: any(named: 'includeMovie'),
      ),
    ).thenAnswer((_) async => entry.value);
  }
}

void _stubSeriesHistory(
  MockSeriesRepository repository,
  Map<int, HistoryPage> pages,
) {
  for (final entry in pages.entries) {
    when(
      () => repository.getHistory(
        page: entry.key,
        pageSize: any(named: 'pageSize'),
        eventType: any(named: 'eventType'),
        includeSeries: any(named: 'includeSeries'),
        includeEpisode: any(named: 'includeEpisode'),
      ),
    ).thenAnswer((_) async => entry.value);
  }
}

void _stubMovieHistoryFor(
  MockMovieRepository repository,
  HistoryEventType eventType,
  Map<int, HistoryPage> pages,
) {
  for (final entry in pages.entries) {
    when(
      () => repository.getHistory(
        page: entry.key,
        pageSize: any(named: 'pageSize'),
        eventType: eventType,
        includeMovie: any(named: 'includeMovie'),
      ),
    ).thenAnswer((_) async => entry.value);
  }
}

void _stubSeriesHistoryFor(
  MockSeriesRepository repository,
  HistoryEventType eventType,
  Map<int, HistoryPage> pages,
) {
  for (final entry in pages.entries) {
    when(
      () => repository.getHistory(
        page: entry.key,
        pageSize: any(named: 'pageSize'),
        eventType: eventType,
        includeSeries: any(named: 'includeSeries'),
        includeEpisode: any(named: 'includeEpisode'),
      ),
    ).thenAnswer((_) async => entry.value);
  }
}

void _stubMovieQueue(
  MockMovieRepository repository, {
  List<QueueItem> records = const [],
}) {
  when(
    () => repository.getQueue(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => _queueItems(records));
}

void _stubSeriesQueue(
  MockSeriesRepository repository, {
  List<QueueItem> records = const [],
}) {
  when(
    () => repository.getQueue(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    ),
  ).thenAnswer((_) async => _queueItems(records));
}

QueueItems _queueItems(List<QueueItem> records) {
  return QueueItems(
    page: 1,
    pageSize: 100,
    sortKey: 'timeleft',
    sortDirection: 'ascending',
    totalRecords: records.length,
    records: records,
  );
}

HistoryPage _historyPage({
  required int page,
  required List<HistoryEvent> records,
  int? totalRecords,
}) {
  return HistoryPage(
    page: page,
    pageSize: 100,
    totalRecords: totalRecords ?? records.length,
    records: records,
  );
}

Instance _instance(String id, InstanceType type) {
  return Instance(
    id: id,
    type: type,
    label: id,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

Torrent _torrent({
  required String hash,
  String? category,
  String? name,
  double progress = 1.0,
  int addedOn = 1700000000,
}) {
  return Torrent(
    hash: hash,
    name: name ?? 'Torrent $hash',
    size: 1000,
    progress: progress,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1,
    status: TorrentStatus.uploading,
    state: 'uploading',
    category: category,
    tags: const [],
    savePath: '/downloads',
    numSeeds: 1,
    numLeechs: 1,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: addedOn,
    priority: 0,
  );
}

HistoryEvent _movieEvent({
  required int id,
  required String downloadId,
  required int movieId,
  required String title,
  required bool hasFile,
  DateTime? date,
  String eventType = 'grabbed',
}) {
  return HistoryEvent.fromJson({
    'id': id,
    'eventType': eventType,
    'date': (date ?? DateTime.utc(2026, 1, 1)).toIso8601String(),
    'sourceTitle': '$title.2016.1080p',
    'movieId': movieId,
    'downloadId': downloadId,
    'quality': _quality,
    'movie': {
      'id': movieId,
      'tmdbId': movieId,
      'title': title,
      'sortTitle': title.toLowerCase(),
      'year': 2016,
      'hasFile': hasFile,
      'added': '2026-01-01T00:00:00Z',
    },
  });
}

HistoryEvent _episodeEvent({
  required int id,
  required String downloadId,
  required int seriesId,
  required String seriesTitle,
  required int seasonNumber,
  required int episodeNumber,
  required bool hasFile,
  DateTime? date,
  String eventType = 'grabbed',
}) {
  return HistoryEvent.fromJson({
    'id': id,
    'eventType': eventType,
    'date': (date ?? DateTime.utc(2026, 1, 1)).toIso8601String(),
    'sourceTitle': '$seriesTitle.S01E05.1080p',
    'seriesId': seriesId,
    'episodeId': 42,
    'downloadId': downloadId,
    'quality': _quality,
    'series': {
      'id': seriesId,
      'tvdbId': seriesId,
      'title': seriesTitle,
      'added': '2026-01-01T00:00:00Z',
    },
    'episode': {
      'id': 42,
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': 'Episode',
      'hasFile': hasFile,
    },
  });
}

const _quality = {
  'quality': {'id': 1, 'name': '1080p'},
  'revision': {'version': 1, 'real': 0},
};
