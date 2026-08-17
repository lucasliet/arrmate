import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/providers/movie_details_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/shared/providers/media_torrents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockQBittorrentService extends Mock implements QBittorrentService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('movieTorrentsProvider', () {
    test('should skip when no qBittorrent instance is configured', () async {
      // Given
      final container = _container(qbittorrent: null);

      // When
      final result = await container.read(movieTorrentsProvider(7).future);

      // Then
      expect(result.qbittorrentSkipped, isTrue);
      expect(result.torrents, isEmpty);
    });

    test('should resolve the torrent grabbed for the movie', () async {
      // Given
      final repository = MockMovieRepository();
      when(() => repository.getMovieHistory(7)).thenAnswer(
        (_) async => [_movieEvent(downloadId: 'AABB', eventType: 'grabbed')],
      );
      final service = MockQBittorrentService();
      final torrent = _torrent(hash: 'aabb', name: 'Arrival.2016.1080p');
      when(service.getTorrents).thenAnswer((_) async => [torrent]);
      final container = _container(
        qbittorrent: service,
        movieRepository: repository,
        movie: _movie(id: 7, title: 'Arrival', hasFile: true),
      );

      // When
      final result = await container.read(movieTorrentsProvider(7).future);

      // Then
      expect(result.qbittorrentSkipped, isFalse);
      expect(result.torrents, hasLength(1));
      final linked = result.torrents.single;
      expect(linked.torrent, torrent);
      expect(linked.link.status, TorrentLinkStatus.linked);
      expect(linked.link.movieId, 7);
      expect(linked.link.mediaTitle, 'Arrival');
      expect(linked.link.instanceId, 'radarr-home');
      expect(linked.link.isCrossSeed, isFalse);
    });

    test(
      'should include cross-seed duplicates of the grabbed torrent',
      () async {
        // Given
        final repository = MockMovieRepository();
        when(() => repository.getMovieHistory(7)).thenAnswer(
          (_) async => [
            _movieEvent(
              downloadId: 'AABB',
              eventType: 'downloadFolderImported',
            ),
          ],
        );
        final service = MockQBittorrentService();
        when(service.getTorrents).thenAnswer(
          (_) async => [
            _torrent(hash: 'aabb', name: 'Arrival.2016.1080p'),
            _torrent(hash: 'ccdd', name: 'arrival.2016.1080p'),
            _torrent(hash: 'eeff', name: 'Dune.2021.1080p'),
          ],
        );
        final container = _container(
          qbittorrent: service,
          movieRepository: repository,
          movie: _movie(id: 7, title: 'Arrival', hasFile: true),
        );

        // When
        final result = await container.read(movieTorrentsProvider(7).future);

        // Then the duplicate is listed and flagged, the unrelated one is not
        expect(result.torrents.map((t) => t.torrent.hash), ['aabb', 'ccdd']);
        expect(result.torrents.map((t) => t.link.isCrossSeed), [false, true]);
        expect(result.torrents.last.link.movieId, 7);
      },
    );

    test('should report fileMissing when the movie has no file', () async {
      // Given
      final repository = MockMovieRepository();
      when(() => repository.getMovieHistory(7)).thenAnswer(
        (_) async => [_movieEvent(downloadId: 'AABB', eventType: 'grabbed')],
      );
      final service = MockQBittorrentService();
      when(service.getTorrents).thenAnswer(
        (_) async => [_torrent(hash: 'aabb', name: 'Arrival.2016.1080p')],
      );
      final container = _container(
        qbittorrent: service,
        movieRepository: repository,
        movie: _movie(id: 7, title: 'Arrival', hasFile: false),
      );

      // When
      final result = await container.read(movieTorrentsProvider(7).future);

      // Then
      expect(result.torrents.single.link.status, TorrentLinkStatus.fileMissing);
    });

    test(
      'should ignore history events other than grabbed or imported',
      () async {
        // Given only a `movieFileDeleted` event carries the hash
        final repository = MockMovieRepository();
        when(() => repository.getMovieHistory(7)).thenAnswer(
          (_) async => [
            _movieEvent(downloadId: 'AABB', eventType: 'movieFileDeleted'),
          ],
        );
        final service = MockQBittorrentService();
        final container = _container(
          qbittorrent: service,
          movieRepository: repository,
          movie: _movie(id: 7, title: 'Arrival', hasFile: true),
        );

        // When
        final result = await container.read(movieTorrentsProvider(7).future);

        // Then the client is never even queried
        expect(result.torrents, isEmpty);
        expect(result.qbittorrentSkipped, isFalse);
        verifyNever(service.getTorrents);
      },
    );
  });

  group('seriesTorrentsProvider', () {
    test('should carry the episode of a single-episode grab', () async {
      // Given
      final repository = MockSeriesRepository();
      when(() => repository.getSeriesHistory(3)).thenAnswer(
        (_) async => [_episodeEvent(downloadId: 'AABB', episodeId: 42)],
      );
      final service = MockQBittorrentService();
      when(service.getTorrents).thenAnswer(
        (_) async => [_torrent(hash: 'aabb', name: 'Severance.S01E05')],
      );
      final container = _container(
        qbittorrent: service,
        seriesRepository: repository,
        series: _series(id: 3, title: 'Severance'),
      );

      // When
      final result = await container.read(seriesTorrentsProvider(3).future);

      // Then
      final linked = result.torrents.single;
      expect(linked.episodeIds, {42});
      expect(linked.link.seriesId, 3);
      expect(linked.link.episodeId, 42);
      expect(linked.link.mediaTitle, 'Severance');
    });

    test('should keep a season pack from claiming a single episode', () async {
      // Given one download covering three episodes
      final repository = MockSeriesRepository();
      when(() => repository.getSeriesHistory(3)).thenAnswer(
        (_) async => [
          _episodeEvent(downloadId: 'AABB', episodeId: 42),
          _episodeEvent(downloadId: 'AABB', episodeId: 43),
          _episodeEvent(downloadId: 'AABB', episodeId: 44),
        ],
      );
      final service = MockQBittorrentService();
      when(service.getTorrents).thenAnswer(
        (_) async => [_torrent(hash: 'aabb', name: 'Severance.S01.1080p')],
      );
      final container = _container(
        qbittorrent: service,
        seriesRepository: repository,
        series: _series(id: 3, title: 'Severance'),
      );

      // When
      final result = await container.read(seriesTorrentsProvider(3).future);

      // Then every episode of the pack is listed, but none is claimed
      final linked = result.torrents.single;
      expect(linked.episodeIds, {42, 43, 44});
      expect(linked.link.episodeId, isNull);
    });

    test('should give a cross-seed the episodes of its source', () async {
      // Given
      final repository = MockSeriesRepository();
      when(() => repository.getSeriesHistory(3)).thenAnswer(
        (_) async => [_episodeEvent(downloadId: 'AABB', episodeId: 42)],
      );
      final service = MockQBittorrentService();
      when(service.getTorrents).thenAnswer(
        (_) async => [
          _torrent(hash: 'aabb', name: 'Severance.S01E05'),
          _torrent(hash: 'ccdd', name: 'severance.s01e05'),
        ],
      );
      final container = _container(
        qbittorrent: service,
        seriesRepository: repository,
        series: _series(id: 3, title: 'Severance'),
      );

      // When
      final result = await container.read(seriesTorrentsProvider(3).future);

      // Then the duplicate is reachable from the same episode sheet
      final crossSeed = result.torrents.last;
      expect(crossSeed.torrent.hash, 'ccdd');
      expect(crossSeed.link.isCrossSeed, isTrue);
      expect(crossSeed.episodeIds, {42});
      expect(crossSeed.link.episodeId, 42);
    });
  });
}

/// Builds a container wired to the given stubs.
///
/// Passing `null` for [qbittorrent] models an app with no download client.
ProviderContainer _container({
  required QBittorrentService? qbittorrent,
  MovieRepository? movieRepository,
  SeriesRepository? seriesRepository,
  Movie? movie,
  Series? series,
}) {
  final container = ProviderContainer(
    overrides: [
      qbittorrentServiceProvider.overrideWithValue(qbittorrent),
      if (movieRepository != null)
        movieRepositoryProvider.overrideWithValue(movieRepository),
      if (seriesRepository != null)
        seriesRepositoryProvider.overrideWithValue(seriesRepository),
      currentRadarrInstanceProvider.overrideWithValue(
        _instance('radarr-home', InstanceType.radarr),
      ),
      currentSonarrInstanceProvider.overrideWithValue(
        _instance('sonarr-home', InstanceType.sonarr),
      ),
      if (movie != null)
        movieDetailsProvider(movie.id).overrideWith((_) async => movie),
      if (series != null)
        seriesDetailsProvider(series.id).overrideWith((_) async => series),
    ],
  );
  addTearDown(container.dispose);
  return container;
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

Movie _movie({required int id, required String title, required bool hasFile}) {
  return Movie.fromJson({
    'id': id,
    'tmdbId': id,
    'title': title,
    'sortTitle': title.toLowerCase(),
    'year': 2016,
    'hasFile': hasFile,
    'added': '2026-01-01T00:00:00Z',
  });
}

Series _series({required int id, required String title}) {
  return Series.fromJson({
    'id': id,
    'tvdbId': id,
    'title': title,
    'added': '2026-01-01T00:00:00Z',
  });
}

HistoryEvent _movieEvent({
  required String downloadId,
  required String eventType,
}) {
  return HistoryEvent.fromJson({
    'id': 1,
    'eventType': eventType,
    'date': '2026-01-01T00:00:00Z',
    'sourceTitle': 'Arrival.2016.1080p',
    'movieId': 7,
    'downloadId': downloadId,
    'quality': _quality,
  });
}

HistoryEvent _episodeEvent({
  required String downloadId,
  required int episodeId,
}) {
  return HistoryEvent.fromJson({
    'id': episodeId,
    'eventType': 'grabbed',
    'date': '2026-01-01T00:00:00Z',
    'sourceTitle': 'Severance.S01.1080p',
    'seriesId': 3,
    'episodeId': episodeId,
    'downloadId': downloadId,
    'quality': _quality,
  });
}

Torrent _torrent({required String hash, required String name}) {
  return Torrent(
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
  );
}

const _quality = {
  'quality': {'id': 1, 'name': '1080p'},
  'revision': {'version': 1, 'real': 0},
};
