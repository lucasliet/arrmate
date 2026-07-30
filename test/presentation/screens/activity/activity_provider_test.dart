import 'package:arrmate/core/constants/api_constants.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/activity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

class _QueueItemFake extends Fake implements QueueItem {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QueueNotifier', () {
    setUpAll(() {
      registerFallbackValue(_QueueItemFake());
    });

    test(
      'should aggregate queue items across Radarr and Sonarr instances',
      () async {
        // Given
        final radarr = _instance('radarr-1', InstanceType.radarr);
        final sonarr = _instance('sonarr-1', InstanceType.sonarr);
        final movieRepo = MockMovieRepository();
        final seriesRepo = MockSeriesRepository();
        _stubMovieQueuePage(
          movieRepo,
          page: 1,
          result: _queuePage([_queueItem(1, title: 'Movie queue')]),
        );
        _stubSeriesQueuePage(
          seriesRepo,
          page: 1,
          result: _queuePage([_queueItem(2, title: 'Series queue')]),
        );

        final container = _container(
          radarrInstances: [radarr],
          sonarrInstances: [sonarr],
          movieRepositories: {radarr: movieRepo},
          seriesRepositories: {sonarr: seriesRepo},
        );
        addTearDown(container.dispose);

        // When
        final items = await container.read(queueProvider.future);

        // Then
        expect(items, hasLength(2));
        expect(
          items.map((item) => item.title),
          containsAll(['Movie queue', 'Series queue']),
        );
        final movieItem = items.firstWhere((item) => item.id == 1);
        expect(movieItem.instanceId, 'radarr-1');
        expect(movieItem.instanceType, InstanceType.radarr);
        final seriesItem = items.firstWhere((item) => item.id == 2);
        expect(seriesItem.instanceId, 'sonarr-1');
        expect(seriesItem.instanceType, InstanceType.sonarr);
      },
    );

    test(
      'should sort items by estimatedCompletionTime with nulls last',
      () async {
        // Given
        final radarr = _instance('radarr-1', InstanceType.radarr);
        final movieRepo = MockMovieRepository();
        final early = DateTime.utc(2024, 1, 1);
        final late = DateTime.utc(2024, 12, 31);
        _stubMovieQueuePage(
          movieRepo,
          page: 1,
          result: _queuePage([
            _queueItem(3, eta: null),
            _queueItem(1, eta: early),
            _queueItem(2, eta: late),
          ]),
        );

        final container = _container(
          radarrInstances: [radarr],
          sonarrInstances: const [],
          movieRepositories: {radarr: movieRepo},
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);

        // When
        final items = await container.read(queueProvider.future);

        // Then
        expect(items.map((item) => item.id), [1, 2, 3]);
      },
    );

    test(
      'should paginate when totalRecords exceeds a single page and dedup by id',
      () async {
        // Given
        final radarr = _instance('radarr-1', InstanceType.radarr);
        final movieRepo = MockMovieRepository();
        _stubMovieQueuePage(
          movieRepo,
          page: 1,
          result: QueueItems(
            page: 1,
            pageSize: ApiConstants.queuePageSize,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 3,
            records: [
              _queueItem(1, title: 'First'),
              _queueItem(2, title: 'Second'),
            ],
          ),
        );
        _stubMovieQueuePage(
          movieRepo,
          page: 2,
          result: QueueItems(
            page: 2,
            pageSize: ApiConstants.queuePageSize,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
            totalRecords: 3,
            records: [
              _queueItem(2, title: 'Second duplicate'),
              _queueItem(3, title: 'Third'),
            ],
          ),
        );

        final container = _container(
          radarrInstances: [radarr],
          sonarrInstances: const [],
          movieRepositories: {radarr: movieRepo},
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);

        // When
        final items = await container.read(queueProvider.future);

        // Then
        expect(items, hasLength(3));
        expect(items.map((item) => item.id), containsAll([1, 2, 3]));
        verify(
          () => movieRepo.getQueue(
            page: any(named: 'page'),
            pageSize: ApiConstants.queuePageSize,
          ),
        ).called(2);
      },
    );

    test(
      'should surface partial failures while keeping healthy instance items',
      () async {
        // Given
        final healthy = _instance('radarr-1', InstanceType.radarr);
        final failing = _instance('radarr-2', InstanceType.radarr);
        final healthyRepo = MockMovieRepository();
        final failingRepo = MockMovieRepository();
        _stubMovieQueuePage(
          healthyRepo,
          page: 1,
          result: _queuePage([_queueItem(1, title: 'Healthy item')]),
        );
        when(
          () => failingRepo.getQueue(
            page: 1,
            pageSize: ApiConstants.queuePageSize,
          ),
        ).thenThrow(Exception('offline'));

        final container = _container(
          radarrInstances: [healthy, failing],
          sonarrInstances: const [],
          movieRepositories: {healthy: healthyRepo, failing: failingRepo},
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);

        // When
        await container.read(queueProvider.future);
        final failures = container.read(queueFailuresProvider);

        // Then
        expect(failures, hasLength(1));
        expect(failures.single.instanceId, 'radarr-2');
        expect(failures.single.message, 'Queue data could not be loaded.');
      },
    );

    test('should return empty list when no instances are configured', () async {
      // Given
      final container = _container(
        radarrInstances: const [],
        sonarrInstances: const [],
        movieRepositories: const {},
        seriesRepositories: const {},
      );
      addTearDown(container.dispose);

      // When
      final items = await container.read(queueProvider.future);

      // Then
      expect(items, isEmpty);
      expect(container.read(queueFailuresProvider), isEmpty);
    });

    group('removeQueueItem', () {
      test(
        'should delegate to movie repository for Radarr instances and refresh',
        () async {
          // Given
          final radarr = _instance('radarr-1', InstanceType.radarr);
          final movieRepo = MockMovieRepository();
          _stubMovieQueuePage(movieRepo, page: 1, result: _queuePage([]));
          _stubMovieDeleteQueueItem(movieRepo);

          final container = _container(
            radarrInstances: [radarr],
            sonarrInstances: const [],
            movieRepositories: {radarr: movieRepo},
            seriesRepositories: const {},
          );
          addTearDown(container.dispose);
          await container.read(queueProvider.future);

          final item = _queueItem(
            10,
            title: 'To remove',
          ).copyWith(instanceId: 'radarr-1', instanceType: InstanceType.radarr);

          // When
          final removed = await container
              .read(queueProvider.notifier)
              .removeQueueItem(item, removeFromClient: false, blocklist: true);

          // Then
          expect(removed, isTrue);
          verify(
            () => movieRepo.deleteQueueItem(
              10,
              removeFromClient: false,
              blocklist: true,
              skipRedownload: false,
            ),
          ).called(1);
        },
      );

      test(
        'should delegate to series repository for Sonarr instances',
        () async {
          // Given
          final sonarr = _instance('sonarr-1', InstanceType.sonarr);
          final seriesRepo = MockSeriesRepository();
          _stubSeriesQueuePage(seriesRepo, page: 1, result: _queuePage([]));
          _stubSeriesDeleteQueueItem(seriesRepo);

          final container = _container(
            radarrInstances: const [],
            sonarrInstances: [sonarr],
            movieRepositories: const {},
            seriesRepositories: {sonarr: seriesRepo},
          );
          addTearDown(container.dispose);
          await container.read(queueProvider.future);

          final item = _queueItem(
            20,
            title: 'To remove',
          ).copyWith(instanceId: 'sonarr-1', instanceType: InstanceType.sonarr);

          // When
          final removed = await container
              .read(queueProvider.notifier)
              .removeQueueItem(item, skipRedownload: true);

          // Then
          expect(removed, isTrue);
          verify(
            () => seriesRepo.deleteQueueItem(
              20,
              removeFromClient: true,
              blocklist: false,
              skipRedownload: true,
            ),
          ).called(1);
        },
      );

      test('should throw when queue item origin is missing', () async {
        // Given
        final container = _container(
          radarrInstances: const [],
          sonarrInstances: const [],
          movieRepositories: const {},
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);
        await container.read(queueProvider.future);

        final item = _queueItem(30, title: 'Orphan');

        // When / Then
        await expectLater(
          container.read(queueProvider.notifier).removeQueueItem(item),
          throwsA(isA<StateError>()),
        );
      });

      test(
        'should throw when the owning instance is no longer configured',
        () async {
          // Given
          final container = _container(
            radarrInstances: const [],
            sonarrInstances: const [],
            movieRepositories: const {},
            seriesRepositories: const {},
          );
          addTearDown(container.dispose);
          await container.read(queueProvider.future);

          final item = _queueItem(40, title: 'Ghost').copyWith(
            instanceId: 'radarr-gone',
            instanceType: InstanceType.radarr,
          );

          // When / Then
          await expectLater(
            container.read(queueProvider.notifier).removeQueueItem(item),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('should throw for qBittorrent instances in the Arr queue', () async {
        // Given
        final qbit = _instance('qbit-1', InstanceType.qbittorrent);
        final container = _container(
          radarrInstances: const [],
          sonarrInstances: const [],
          movieRepositories: const {},
          seriesRepositories: const {},
          qbittorrentInstances: [qbit],
        );
        addTearDown(container.dispose);
        await container.read(queueProvider.future);

        final item = _queueItem(50, title: 'qBit item').copyWith(
          instanceId: 'qbit-1',
          instanceType: InstanceType.qbittorrent,
        );

        // When / Then
        await expectLater(
          container.read(queueProvider.notifier).removeQueueItem(item),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

ProviderContainer _container({
  required List<Instance> radarrInstances,
  required List<Instance> sonarrInstances,
  required Map<Instance, MovieRepository> movieRepositories,
  required Map<Instance, SeriesRepository> seriesRepositories,
  List<Instance> qbittorrentInstances = const [],
}) {
  return ProviderContainer(
    overrides: [
      instancesByTypeProvider(
        InstanceType.radarr,
      ).overrideWithValue(radarrInstances),
      instancesByTypeProvider(
        InstanceType.sonarr,
      ).overrideWithValue(sonarrInstances),
      instancesByTypeProvider(
        InstanceType.qbittorrent,
      ).overrideWithValue(qbittorrentInstances),
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

QueueItem _queueItem(int id, {String title = 'Item', DateTime? eta}) {
  return QueueItem(
    id: id,
    title: title,
    status: QueueStatus.downloading,
    protocol: 'torrent',
    sizeleft: 0,
    estimatedCompletionTime: eta,
  );
}

QueueItems _queuePage(List<QueueItem> records) {
  return QueueItems(
    page: 1,
    pageSize: ApiConstants.queuePageSize,
    sortKey: 'timeleft',
    sortDirection: 'ascending',
    totalRecords: records.length,
    records: records,
  );
}

void _stubMovieQueuePage(
  MockMovieRepository repository, {
  required int page,
  required QueueItems result,
}) {
  when(
    () => repository.getQueue(page: page, pageSize: ApiConstants.queuePageSize),
  ).thenAnswer((_) async => result);
}

void _stubSeriesQueuePage(
  MockSeriesRepository repository, {
  required int page,
  required QueueItems result,
}) {
  when(
    () => repository.getQueue(page: page, pageSize: ApiConstants.queuePageSize),
  ).thenAnswer((_) async => result);
}

void _stubMovieDeleteQueueItem(MockMovieRepository repository) {
  when(
    () => repository.deleteQueueItem(
      any(),
      removeFromClient: any(named: 'removeFromClient'),
      blocklist: any(named: 'blocklist'),
      skipRedownload: any(named: 'skipRedownload'),
    ),
  ).thenAnswer((_) async {});
}

void _stubSeriesDeleteQueueItem(MockSeriesRepository repository) {
  when(
    () => repository.deleteQueueItem(
      any(),
      removeFromClient: any(named: 'removeFromClient'),
      blocklist: any(named: 'blocklist'),
      skipRedownload: any(named: 'skipRedownload'),
    ),
  ).thenAnswer((_) async {});
}
