import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/services/playback_launch_service.dart';
import 'package:arrmate/data/api/jellyfin_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/watching_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockJellyfinService extends Mock implements JellyfinService {}

class _MockMovieRepository extends Mock implements MovieRepository {}

class _MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  group('matchResumeItemsToLibrary', () {
    final radarrInstance = Instance(
      id: 'radarr-1',
      type: InstanceType.radarr,
      label: 'Radarr',
      url: 'http://radarr.local',
      apiKey: 'r-key',
    );
    final sonarrInstance = Instance(
      id: 'sonarr-1',
      type: InstanceType.sonarr,
      label: 'Sonarr',
      url: 'http://sonarr.local',
      apiKey: 's-key',
    );

    test(
      'matches movies by tmdbId, imdbId, path, or title+year and skips unmatched items',
      () {
        // Given
        final dune = _movie(
          id: 1,
          title: 'Dune',
          year: 2021,
          tmdbId: 438631,
          path: '/movies/Dune (2021)',
        );
        final arrival = _movie(
          id: 2,
          title: 'Arrival',
          year: 2016,
          tmdbId: 329865,
          imdbId: 'tt2543164',
          path: '/movies/Arrival (2016)',
        );
        final bladeRunner = _movie(
          id: 3,
          title: 'Blade Runner 2049',
          year: 2017,
          tmdbId: 335984,
          path: '/movies/Blade Runner 2049',
          filePath: '/movies/Blade Runner 2049/BR2049.mkv',
        );
        final sicario = _movie(
          id: 4,
          title: 'Sicario',
          year: 2015,
          tmdbId: 273481,
          path: '/movies/Sicario',
        );

        final resumeItems = [
          _jellyfinMovie(
            id: 'jf-dune',
            name: 'Dune: Part One',
            providerIds: const {'Tmdb': '438631'},
          ),
          _jellyfinMovie(
            id: 'jf-arrival',
            name: 'Arrival',
            providerIds: const {'Imdb': 'TT2543164'},
          ),
          _jellyfinMovie(
            id: 'jf-br',
            name: 'Other Title',
            path: '/jellyfin/movies/BR2049.mkv',
          ),
          _jellyfinMovie(
            id: 'jf-sicario',
            name: 'Sicario',
            productionYear: 2015,
          ),
          _jellyfinMovie(
            id: 'jf-unmatched',
            name: 'Not In Radarr',
            productionYear: 2024,
            providerIds: const {'Tmdb': '999999'},
          ),
        ];

        // When
        final matched = matchResumeItemsToLibrary(
          resumeItems: resumeItems,
          movies: [
            LibraryMovieEntry(instance: radarrInstance, movie: dune),
            LibraryMovieEntry(instance: radarrInstance, movie: arrival),
            LibraryMovieEntry(instance: radarrInstance, movie: bladeRunner),
            LibraryMovieEntry(instance: radarrInstance, movie: sicario),
          ],
          series: const [],
        );

        // Then
        expect(matched.map((item) => item.movie?.id).toList(), [1, 2, 3, 4]);
        expect(matched.first.displayTitle, 'Dune');
        expect(matched.first.subtitle, '2021');
        expect(matched.first.progress, closeTo(0.5, 0.001));
      },
    );

    test(
      'matches episodes by series folder path or normalized series title',
      () {
        // Given
        final severance = _series(
          id: 10,
          title: 'Severance (2022)',
          path: '/tv/Severance',
        );
        final dark = _series(id: 20, title: 'Dark', path: '/tv/Dark');

        final resumeItems = [
          _jellyfinEpisode(
            id: 'jf-sev',
            name: 'Half Loop',
            seriesName: 'Severance',
            seasonNumber: 1,
            episodeNumber: 2,
            path: '/mnt/media/Severance/Season 01/S01E02.mkv',
          ),
          _jellyfinEpisode(
            id: 'jf-dark',
            name: 'Secrets',
            seriesName: 'Unrelated Name',
            seasonNumber: 1,
            episodeNumber: 1,
            path: '/tv/Dark/Season 01/S01E01.mkv',
          ),
          _jellyfinEpisode(
            id: 'jf-unknown',
            name: 'Pilot',
            seriesName: 'Unknown Show',
            seasonNumber: 1,
            episodeNumber: 1,
            path: '/tv/Unknown Show/S01E01.mkv',
          ),
        ];

        // When
        final matched = matchResumeItemsToLibrary(
          resumeItems: resumeItems,
          movies: const [],
          series: [
            LibrarySeriesEntry(instance: sonarrInstance, series: severance),
            LibrarySeriesEntry(instance: sonarrInstance, series: dark),
          ],
        );

        // Then
        expect(matched.map((item) => item.series?.id).toList(), [10, 20]);
        expect(matched.first.displayTitle, 'Severance (2022)');
        expect(matched.first.subtitle, 'S01E02 · Half Loop');
        expect(
          matched.first.playbackTitle,
          'Severance (2022) · S01E02 · Half Loop',
        );
      },
    );
  });

  group('watchingItemsProvider', () {
    final jellyfinInstance = Instance(
      id: 'jf-1',
      type: InstanceType.jellyfin,
      label: 'Jellyfin',
      url: 'http://jf.local',
      apiKey: '',
      userSession: const InstanceUserSession(
        accessToken: 'tok-1',
        deviceId: 'dev-1',
        userId: 'user-1',
      ),
    );
    final radarrInstance = Instance(
      id: 'radarr-1',
      type: InstanceType.radarr,
      label: 'Radarr',
      url: 'http://radarr.local',
      apiKey: 'r-key',
    );
    final sonarrInstance = Instance(
      id: 'sonarr-1',
      type: InstanceType.sonarr,
      label: 'Sonarr',
      url: 'http://sonarr.local',
      apiKey: 's-key',
    );

    test(
      'fetches resume items and filters them against Radarr and Sonarr libraries',
      () async {
        // Given
        final jellyfinService = _MockJellyfinService();
        when(() => jellyfinService.instance).thenReturn(jellyfinInstance);
        when(() => jellyfinService.getResumeItems()).thenAnswer(
          (_) async => [
            _jellyfinMovie(
              id: 'jf-dune',
              name: 'Dune',
              providerIds: const {'Tmdb': '438631'},
            ),
            _jellyfinEpisode(
              id: 'jf-sev',
              name: 'Good News About Hell',
              seriesName: 'Severance',
              seasonNumber: 1,
              episodeNumber: 1,
            ),
            _jellyfinMovie(
              id: 'jf-external',
              name: 'External Movie',
              providerIds: const {'Tmdb': '111111'},
            ),
          ],
        );

        final movieRepo = _MockMovieRepository();
        when(() => movieRepo.getMovies()).thenAnswer(
          (_) async => [
            _movie(id: 7, title: 'Dune', year: 2021, tmdbId: 438631),
          ],
        );

        final seriesRepo = _MockSeriesRepository();
        when(() => seriesRepo.getSeries()).thenAnswer(
          (_) async => [
            _series(id: 9, title: 'Severance', path: '/tv/Severance'),
          ],
        );

        final launchService = PlaybackLaunchService(
          jellyfinServiceFactory: (_) => jellyfinService,
        );

        final container = ProviderContainer(
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
            instancesByTypeProvider(
              InstanceType.radarr,
            ).overrideWithValue([radarrInstance]),
            instancesByTypeProvider(
              InstanceType.sonarr,
            ).overrideWithValue([sonarrInstance]),
            playbackLaunchServiceProvider.overrideWithValue(launchService),
            movieRepositoryForInstanceProvider(
              radarrInstance,
            ).overrideWithValue(movieRepo),
            seriesRepositoryForInstanceProvider(
              sonarrInstance,
            ).overrideWithValue(seriesRepo),
          ],
        );
        addTearDown(container.dispose);

        // When
        final items = await container.read(watchingItemsProvider.future);

        // Then
        expect(items, hasLength(2));
        expect(items[0].movie?.id, 7);
        expect(items[1].series?.id, 9);
      },
    );

    test(
      'marks Jellyfin session as expired and returns empty list on UnauthorizedError',
      () async {
        // Given
        final jellyfinService = _MockJellyfinService();
        when(() => jellyfinService.instance).thenReturn(jellyfinInstance);
        when(
          () => jellyfinService.getResumeItems(),
        ).thenThrow(const UnauthorizedError('Expired'));

        final launchService = PlaybackLaunchService(
          jellyfinServiceFactory: (_) => jellyfinService,
        );

        final container = ProviderContainer(
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
            instancesByTypeProvider(
              InstanceType.radarr,
            ).overrideWithValue([radarrInstance]),
            instancesByTypeProvider(
              InstanceType.sonarr,
            ).overrideWithValue(const []),
            playbackLaunchServiceProvider.overrideWithValue(launchService),
          ],
        );
        addTearDown(container.dispose);

        // When
        final items = await container.read(watchingItemsProvider.future);
        await pumpEventQueue();

        // Then
        expect(items, isEmpty);
        expect(
          container.read(jellyfinSessionExpiredProvider),
          contains(jellyfinInstance.id),
        );
      },
    );
  });
}

Movie _movie({
  required int id,
  required String title,
  required int year,
  required int tmdbId,
  String? imdbId,
  String? path,
  String? filePath,
}) {
  return Movie.fromJson({
    'id': id,
    'title': title,
    'sortTitle': title.toLowerCase(),
    'year': year,
    'tmdbId': tmdbId,
    'imdbId': ?imdbId,
    'status': 'released',
    'monitored': true,
    'hasFile': true,
    'qualityProfileId': 1,
    'runtime': 120,
    'sizeOnDisk': 1000,
    'added': '2024-01-01T00:00:00.000Z',
    'path': ?path,
    if (filePath != null)
      'movieFile': {
        'id': id * 10,
        'relativePath': filePath.split('/').last,
        'path': filePath,
        'size': 1000,
        'dateAdded': '2024-01-01T00:00:00.000Z',
      },
  });
}

Series _series({required int id, required String title, String? path}) {
  return Series.fromJson({
    'id': id,
    'title': title,
    'sortTitle': title.toLowerCase(),
    'year': 2022,
    'tvdbId': id * 100,
    'status': 'continuing',
    'seriesType': 'standard',
    'monitored': true,
    'qualityProfileId': 1,
    'seasonFolder': true,
    'runtime': 50,
    'added': '2024-01-01T00:00:00.000Z',
    'path': ?path,
  });
}

JellyfinItem _jellyfinMovie({
  required String id,
  required String name,
  String? path,
  int? productionYear,
  Map<String, String> providerIds = const {},
}) {
  return JellyfinItem(
    id: id,
    name: name,
    type: 'Movie',
    path: path,
    productionYear: productionYear,
    providerIds: providerIds,
    playbackPositionTicks: 30000000000,
    runTimeTicks: 60000000000,
    mediaSources: const [JellyfinMediaSource(id: 'src-1', container: 'mkv')],
  );
}

JellyfinItem _jellyfinEpisode({
  required String id,
  required String name,
  required String seriesName,
  required int seasonNumber,
  required int episodeNumber,
  String? path,
}) {
  return JellyfinItem(
    id: id,
    name: name,
    type: 'Episode',
    seriesName: seriesName,
    parentIndexNumber: seasonNumber,
    indexNumber: episodeNumber,
    path: path,
    playbackPositionTicks: 15000000000,
    runTimeTicks: 30000000000,
    mediaSources: const [JellyfinMediaSource(id: 'src-1', container: 'mkv')],
  );
}
