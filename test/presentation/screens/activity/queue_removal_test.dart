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

void main() {
  group('QueueNotifier', () {
    test('should delete only the originating Sonarr queue item', () async {
      final radarr = _instance('radarr', InstanceType.radarr);
      final sonarr = _instance('sonarr', InstanceType.sonarr);
      final movieRepository = MockMovieRepository();
      final seriesRepository = MockSeriesRepository();
      _stubEmptyMovieQueue(movieRepository);
      _stubEmptySeriesQueue(seriesRepository);
      when(
        () => seriesRepository.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});
      final container = _container(
        radarrInstances: [radarr],
        sonarrInstances: [sonarr],
        movieRepositories: {radarr: movieRepository},
        seriesRepositories: {sonarr: seriesRepository},
      );
      addTearDown(container.dispose);
      await container.read(queueProvider.future);
      final item = _queueItem(
        id: 42,
        instanceId: sonarr.id,
        instanceType: sonarr.type,
      );

      await container
          .read(queueProvider.notifier)
          .removeQueueItem(item, blocklist: true);

      verify(
        () => seriesRepository.deleteQueueItem(
          42,
          removeFromClient: true,
          blocklist: true,
          skipRedownload: false,
        ),
      ).called(1);
      verifyNever(
        () => movieRepository.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      );
    });

    test('should delete only the originating Radarr instance item', () async {
      final home = _instance('radarr-home', InstanceType.radarr);
      final remote = _instance('radarr-remote', InstanceType.radarr);
      final homeRepository = MockMovieRepository();
      final remoteRepository = MockMovieRepository();
      _stubEmptyMovieQueue(homeRepository);
      _stubEmptyMovieQueue(remoteRepository);
      when(
        () => remoteRepository.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});
      final container = _container(
        radarrInstances: [home, remote],
        movieRepositories: {home: homeRepository, remote: remoteRepository},
      );
      addTearDown(container.dispose);
      await container.read(queueProvider.future);
      final item = _queueItem(
        id: 42,
        instanceId: remote.id,
        instanceType: remote.type,
      );

      await container.read(queueProvider.notifier).removeQueueItem(item);

      verify(
        () => remoteRepository.deleteQueueItem(
          42,
          removeFromClient: true,
          blocklist: false,
          skipRedownload: false,
        ),
      ).called(1);
      verifyNever(
        () => homeRepository.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      );
    });

    test('should reject deletion when queue origin is missing', () async {
      final container = _container();
      addTearDown(container.dispose);
      await container.read(queueProvider.future);

      await expectLater(
        container
            .read(queueProvider.notifier)
            .removeQueueItem(_queueItem(id: 42)),
        throwsStateError,
      );
    });

    test('should aggregate every instance and fetch all queue pages', () async {
      final radarr = _instance('radarr', InstanceType.radarr);
      final sonarr = _instance('sonarr', InstanceType.sonarr);
      final movieRepository = MockMovieRepository();
      final seriesRepository = MockSeriesRepository();
      when(() => movieRepository.getQueue(page: 1, pageSize: 100)).thenAnswer(
        (_) async =>
            _queuePage(page: 1, totalRecords: 2, records: [_queueItem(id: 1)]),
      );
      when(() => movieRepository.getQueue(page: 2, pageSize: 100)).thenAnswer(
        (_) async =>
            _queuePage(page: 2, totalRecords: 2, records: [_queueItem(id: 2)]),
      );
      when(() => seriesRepository.getQueue(page: 1, pageSize: 100)).thenAnswer(
        (_) async =>
            _queuePage(page: 1, totalRecords: 1, records: [_queueItem(id: 3)]),
      );
      final container = _container(
        radarrInstances: [radarr],
        sonarrInstances: [sonarr],
        movieRepositories: {radarr: movieRepository},
        seriesRepositories: {sonarr: seriesRepository},
      );
      addTearDown(container.dispose);

      final items = await container.read(queueProvider.future);

      expect(items, hasLength(3));
      expect(items.where((item) => item.instanceId == radarr.id), hasLength(2));
      expect(items.where((item) => item.instanceId == sonarr.id), hasLength(1));
      expect(
        items
            .where((item) => item.instanceId == radarr.id)
            .every((item) => item.instanceType == InstanceType.radarr),
        isTrue,
      );
      verify(() => movieRepository.getQueue(page: 2, pageSize: 100)).called(1);
    });
  });
}

ProviderContainer _container({
  List<Instance> radarrInstances = const [],
  List<Instance> sonarrInstances = const [],
  Map<Instance, MovieRepository> movieRepositories = const {},
  Map<Instance, SeriesRepository> seriesRepositories = const {},
}) {
  return ProviderContainer(
    overrides: [
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

QueueItem _queueItem({
  required int id,
  String? instanceId,
  InstanceType? instanceType,
}) {
  return QueueItem(
    id: id,
    instanceId: instanceId,
    instanceType: instanceType,
    title: 'Queue item $id',
    status: QueueStatus.downloading,
    protocol: 'torrent',
    sizeleft: 1,
  );
}

QueueItems _queuePage({
  required int page,
  required int totalRecords,
  required List<QueueItem> records,
}) {
  return QueueItems(
    records: records,
    totalRecords: totalRecords,
    page: page,
    pageSize: 100,
    sortKey: 'timeleft',
    sortDirection: 'ascending',
  );
}

void _stubEmptyMovieQueue(MockMovieRepository repository) {
  when(
    () => repository.getQueue(page: 1, pageSize: 100),
  ).thenAnswer((_) async => _queuePage(page: 1, totalRecords: 0, records: []));
}

void _stubEmptySeriesQueue(MockSeriesRepository repository) {
  when(
    () => repository.getQueue(page: 1, pageSize: 100),
  ).thenAnswer((_) async => _queuePage(page: 1, totalRecords: 0, records: []));
}
