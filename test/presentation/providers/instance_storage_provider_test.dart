import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/repositories.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instance_storage_provider.dart';
import 'package:arrmate/presentation/providers/jellyfin_session_state_provider.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInstanceRepository extends Mock implements InstanceRepository {}

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(_instance('fallback', InstanceType.radarr));
  });

  late Instance radarr;
  late Instance sonarr;
  late MockInstanceRepository instanceRepository;
  late MockMovieRepository movieRepository;
  late MockSeriesRepository seriesRepository;

  setUp(() {
    radarr = _instance('radarr-home', InstanceType.radarr);
    sonarr = _instance('sonarr-home', InstanceType.sonarr);
    instanceRepository = MockInstanceRepository();
    movieRepository = MockMovieRepository();
    seriesRepository = MockSeriesRepository();
  });

  test('should load version, library statistics, and disk space', () async {
    // Given
    _stubStatus(instanceRepository, radarr, '5.0.0');
    _stubStatus(instanceRepository, sonarr, '4.0.0');
    _stubDiskSpace(instanceRepository, radarr);
    _stubDiskSpace(instanceRepository, sonarr);
    when(
      () => movieRepository.getMovies(),
    ).thenAnswer((_) async => [_movie(1, 1500), _movie(2, 2500)]);
    when(
      () => seriesRepository.getSeries(),
    ).thenAnswer((_) async => [_series(1, 10, 6000)]);
    final container = _container(
      radarr: radarr,
      sonarr: sonarr,
      instanceRepository: instanceRepository,
      movieRepository: movieRepository,
      seriesRepository: seriesRepository,
    );
    addTearDown(container.dispose);

    // When
    final overviews = await container.read(
      instanceStorageOverviewsProvider.future,
    );

    // Then
    expect(overviews, hasLength(2));
    expect(overviews[0].version, '5.0.0');
    expect(overviews[0].library?.movieCount, 2);
    expect(overviews[0].library?.sizeOnDisk, 4000);
    expect(overviews[0].diskSpaces?.single.usedSpace, 600);
    expect(overviews[0].failures, isEmpty);
    expect(overviews[1].version, '4.0.0');
    expect(overviews[1].library?.seriesCount, 1);
    expect(overviews[1].library?.episodeCount, 10);
    expect(overviews[1].library?.sizeOnDisk, 6000);
  });

  test('should keep healthy data when one instance section fails', () async {
    // Given
    _stubStatus(instanceRepository, radarr, '5.0.0');
    _stubStatus(instanceRepository, sonarr, '4.0.0');
    when(
      () => instanceRepository.getDiskSpace(radarr),
    ).thenThrow(Exception('offline disk endpoint'));
    _stubDiskSpace(instanceRepository, sonarr);
    when(
      () => movieRepository.getMovies(),
    ).thenAnswer((_) async => [_movie(1, 1500)]);
    when(
      () => seriesRepository.getSeries(),
    ).thenAnswer((_) async => [_series(1, 10, 6000)]);
    final container = _container(
      radarr: radarr,
      sonarr: sonarr,
      instanceRepository: instanceRepository,
      movieRepository: movieRepository,
      seriesRepository: seriesRepository,
    );
    addTearDown(container.dispose);

    // When
    final overviews = await container.read(
      instanceStorageOverviewsProvider.future,
    );

    // Then
    final radarrOverview = overviews.first;
    final sonarrOverview = overviews.last;
    expect(radarrOverview.status, isNotNull);
    expect(radarrOverview.library?.movieCount, 1);
    expect(radarrOverview.diskSpaces, isNull);
    expect(radarrOverview.failures, [
      const InstanceOverviewFailure(
        section: InstanceOverviewSection.diskSpace,
        message: 'Disk space information is unavailable.',
      ),
    ]);
    expect(sonarrOverview.diskSpaces, isNotEmpty);
    expect(sonarrOverview.failures, isEmpty);
  });

  group('jellyfinSessionStatusProvider', () {
    const expiredMessage =
        'Your Jellyfin session has expired. Sign in again in the instance '
        'settings (API Key field as username:password).';

    test('should flag an instance whose session the server rejected', () async {
      // Given
      final jellyfin = _jellyfin('jellyfin-home');
      when(
        () => instanceRepository.getSystemStatus(jellyfin),
      ).thenThrow(const UnauthorizedError(expiredMessage));
      final container = _jellyfinContainer(
        instances: [jellyfin],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      expect(
        container.read(jellyfinSessionExpiredProvider),
        contains('jellyfin-home'),
      );
    });

    test('should clear the flag once the server accepts the session', () async {
      // Given
      final jellyfin = _jellyfin('jellyfin-home');
      when(
        () => instanceRepository.getSystemStatus(jellyfin),
      ).thenAnswer((_) async => const InstanceStatus(
          appName: 'Jellyfin',
          instanceName: 'Jellyfin',
          version: '10.9.0',
        ),
      );
      final container = _jellyfinContainer(
        instances: [jellyfin],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);
      container
          .read(jellyfinSessionExpiredProvider.notifier)
          .markExpired('jellyfin-home');

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      expect(
        container.read(jellyfinSessionExpiredProvider),
        isNot(contains('jellyfin-home')),
      );
    });

    test('should not flag an unreachable server', () async {
      // Given
      final jellyfin = _jellyfin('jellyfin-home');
      when(
        () => instanceRepository.getSystemStatus(jellyfin),
      ).thenThrow(const ConnectionError());
      final container = _jellyfinContainer(
        instances: [jellyfin],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      expect(container.read(jellyfinSessionExpiredProvider), isEmpty);
    });

    test('should not flag on an unexpected error', () async {
      // Given
      final jellyfin = _jellyfin('jellyfin-home');
      when(
        () => instanceRepository.getSystemStatus(jellyfin),
      ).thenThrow(Exception('server exploded'));
      final container = _jellyfinContainer(
        instances: [jellyfin],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      expect(container.read(jellyfinSessionExpiredProvider), isEmpty);
    });

    test('should check each instance independently', () async {
      // Given
      final offline = _jellyfin('jellyfin-offline');
      final expired = _jellyfin('jellyfin-expired');
      when(
        () => instanceRepository.getSystemStatus(offline),
      ).thenThrow(const TimeoutError());
      when(
        () => instanceRepository.getSystemStatus(expired),
      ).thenThrow(const UnauthorizedError(expiredMessage));
      final container = _jellyfinContainer(
        instances: [offline, expired],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      expect(container.read(jellyfinSessionExpiredProvider), {
        'jellyfin-expired',
      });
    });

    test('should skip instances without a session', () async {
      // Given
      final apiKeyInstance = _jellyfin('jellyfin-key', withSession: false);
      final container = _jellyfinContainer(
        instances: [apiKeyInstance],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      verifyNever(() => instanceRepository.getSystemStatus(any()));
      expect(container.read(jellyfinSessionExpiredProvider), isEmpty);
    });

    test('should not call the repository without Jellyfin instances', () async {
      // Given
      final container = _jellyfinContainer(
        instances: const [],
        instanceRepository: instanceRepository,
      );
      addTearDown(container.dispose);

      // When
      await container.read(jellyfinSessionStatusProvider.future);

      // Then
      verifyNever(() => instanceRepository.getSystemStatus(any()));
    });
  });
}

ProviderContainer _container({
  required Instance radarr,
  required Instance sonarr,
  required InstanceRepository instanceRepository,
  required MovieRepository movieRepository,
  required SeriesRepository seriesRepository,
}) {
  return ProviderContainer(
    overrides: [
      instancesByTypeProvider(InstanceType.radarr).overrideWithValue([radarr]),
      instancesByTypeProvider(InstanceType.sonarr).overrideWithValue([sonarr]),
      instanceRepositoryProvider.overrideWithValue(instanceRepository),
      movieRepositoryForInstanceProvider(
        radarr,
      ).overrideWithValue(movieRepository),
      seriesRepositoryForInstanceProvider(
        sonarr,
      ).overrideWithValue(seriesRepository),
    ],
  );
}

ProviderContainer _jellyfinContainer({
  required List<Instance> instances,
  required InstanceRepository instanceRepository,
}) {
  return ProviderContainer(
    overrides: [
      instancesByTypeProvider(
        InstanceType.jellyfin,
      ).overrideWithValue(instances),
      instanceRepositoryProvider.overrideWithValue(instanceRepository),
    ],
  );
}

Instance _jellyfin(String id, {bool withSession = true}) {
  return Instance(
    id: id,
    type: InstanceType.jellyfin,
    label: InstanceType.jellyfin.label,
    url: 'https://$id.example.com',
    apiKey: withSession ? '' : 'key',
    userSession: withSession
        ? const InstanceUserSession(
            accessToken: 'session-token',
            deviceId: 'arrmate-device',
            isAdministrator: true,
            deviceTag: 'a1b2c3d4',
          )
        : null,
  );
}

Instance _instance(String id, InstanceType type) {
  return Instance(
    id: id,
    type: type,
    label: type.label,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

void _stubStatus(
  MockInstanceRepository repository,
  Instance instance,
  String version,
) {
  when(() => repository.getSystemStatus(instance)).thenAnswer(
    (_) async => InstanceStatus(
      appName: instance.type.label,
      instanceName: instance.label,
      version: version,
    ),
  );
}

void _stubDiskSpace(MockInstanceRepository repository, Instance instance) {
  when(() => repository.getDiskSpace(instance)).thenAnswer(
    (_) async => const [
      InstanceDiskSpace(path: '/media', freeSpace: 400, totalSpace: 1000),
    ],
  );
}

Movie _movie(int id, int sizeOnDisk) {
  return Movie(
    guid: id,
    tmdbId: id,
    title: 'Movie $id',
    sortTitle: 'Movie $id',
    year: 2026,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    sizeOnDisk: sizeOnDisk,
    added: DateTime(2026),
  );
}

Series _series(int id, int episodeFileCount, int sizeOnDisk) {
  return Series(
    guid: id,
    title: 'Series $id',
    sortTitle: 'Series $id',
    tvdbId: id,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2026,
    added: DateTime(2026),
    statistics: SeriesStatistics(
      sizeOnDisk: sizeOnDisk,
      seasonCount: 1,
      episodeCount: episodeFileCount,
      episodeFileCount: episodeFileCount,
      totalEpisodeCount: episodeFileCount,
      percentOfEpisodes: 100,
    ),
  );
}
