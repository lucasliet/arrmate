import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryNotifier', () {
    test('should aggregate history from every configured instance', () async {
      final firstRadarr = _instance('radarr-home', InstanceType.radarr);
      final secondRadarr = _instance('radarr-remote', InstanceType.radarr);
      final sonarr = _instance('sonarr-home', InstanceType.sonarr);
      final firstRepository = MockMovieRepository();
      final secondRepository = MockMovieRepository();
      final seriesRepository = MockSeriesRepository();
      _stubHistoryPage(
        firstRepository,
        page: 1,
        result: _historyPage(
          page: 1,
          records: [_historyEvent(1, DateTime.utc(2026, 1, 1))],
        ),
      );
      _stubHistoryPage(
        secondRepository,
        page: 1,
        result: _historyPage(
          page: 1,
          records: [_historyEvent(2, DateTime.utc(2026, 1, 2))],
        ),
      );
      _stubSeriesHistoryPage(
        seriesRepository,
        page: 1,
        result: _historyPage(
          page: 1,
          records: [_historyEvent(3, DateTime.utc(2026, 1, 3))],
        ),
      );
      final container = _container(
        radarrInstances: [firstRadarr, secondRadarr],
        sonarrInstances: [sonarr],
        movieRepositories: {
          firstRadarr: firstRepository,
          secondRadarr: secondRepository,
        },
        seriesRepositories: {sonarr: seriesRepository},
      );
      addTearDown(container.dispose);

      final events = await container.read(activityHistoryProvider.future);

      expect(events, hasLength(3));
      expect(events.map((event) => event.instanceId).toSet(), {
        firstRadarr.id,
        secondRadarr.id,
        sonarr.id,
      });
      expect(events.map((event) => event.id), [3, 2, 1]);
    });

    test(
      'should keep independent cursors and global order after loading more',
      () async {
        final radarr = _instance('radarr-home', InstanceType.radarr);
        final sonarr = _instance('sonarr-home', InstanceType.sonarr);
        final movieRepository = MockMovieRepository();
        final seriesRepository = MockSeriesRepository();
        _stubHistoryPage(
          movieRepository,
          page: 1,
          result: _historyPage(
            page: 1,
            totalRecords: 2,
            records: [_historyEvent(1, DateTime.utc(2026, 1, 1))],
          ),
        );
        _stubHistoryPage(
          movieRepository,
          page: 2,
          result: _historyPage(
            page: 2,
            totalRecords: 2,
            records: [_historyEvent(2, DateTime.utc(2026, 1, 2))],
          ),
        );
        _stubSeriesHistoryPage(
          seriesRepository,
          page: 1,
          result: _historyPage(
            page: 1,
            records: [_historyEvent(3, DateTime.utc(2026, 1, 3))],
          ),
        );
        final container = _container(
          radarrInstances: [radarr],
          sonarrInstances: [sonarr],
          movieRepositories: {radarr: movieRepository},
          seriesRepositories: {sonarr: seriesRepository},
        );
        addTearDown(container.dispose);
        await container.read(activityHistoryProvider.future);

        await container.read(activityHistoryProvider.notifier).loadMore();

        final events = container.read(activityHistoryProvider).value!;
        expect(events.map((event) => event.id), [3, 2, 1]);
        verify(
          () => movieRepository.getHistory(
            page: 2,
            pageSize: 50,
            eventType: null,
          ),
        ).called(1);
        verifyNever(
          () => seriesRepository.getHistory(
            page: 2,
            pageSize: 50,
            eventType: null,
          ),
        );
      },
    );

    test(
      'should deduplicate shifted records when loading the next page',
      () async {
        // Given
        final radarr = _instance('radarr-home', InstanceType.radarr);
        final repository = MockMovieRepository();
        _stubHistoryPage(
          repository,
          page: 1,
          result: _historyPage(
            page: 1,
            totalRecords: 2,
            records: [_historyEvent(1, DateTime.utc(2026, 1, 2))],
          ),
        );
        _stubHistoryPage(
          repository,
          page: 2,
          result: _historyPage(
            page: 2,
            totalRecords: 2,
            records: [
              _historyEvent(1, DateTime.utc(2026, 1, 2)),
              _historyEvent(2, DateTime.utc(2026, 1, 1)),
            ],
          ),
        );
        final container = _container(
          radarrInstances: [radarr],
          sonarrInstances: const [],
          movieRepositories: {radarr: repository},
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);
        await container.read(activityHistoryProvider.future);

        // When
        await container.read(activityHistoryProvider.notifier).loadMore();

        // Then
        final events = container.read(activityHistoryProvider).value!;
        expect(events.map((event) => event.id), [1, 2]);
      },
    );

    test(
      'should expose only the selected instance events when filtered',
      () async {
        final firstRadarr = _instance('radarr-home', InstanceType.radarr);
        final secondRadarr = _instance('radarr-remote', InstanceType.radarr);
        final firstRepository = MockMovieRepository();
        final secondRepository = MockMovieRepository();
        _stubHistoryPage(
          firstRepository,
          page: 1,
          result: _historyPage(
            page: 1,
            records: [_historyEvent(1, DateTime.utc(2026, 1, 1))],
          ),
        );
        _stubHistoryPage(
          secondRepository,
          page: 1,
          result: _historyPage(
            page: 1,
            records: [_historyEvent(2, DateTime.utc(2026, 1, 2))],
          ),
        );
        final container = _container(
          radarrInstances: [firstRadarr, secondRadarr],
          sonarrInstances: const [],
          movieRepositories: {
            firstRadarr: firstRepository,
            secondRadarr: secondRepository,
          },
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);
        await container.read(activityHistoryProvider.future);

        container.read(historyInstanceFilterProvider.notifier).state =
            secondRadarr.id;

        final filtered = container.read(filteredActivityHistoryProvider).value!;

        expect(filtered, hasLength(1));
        expect(filtered.single.instanceId, secondRadarr.id);
      },
    );

    test('should ignore stale pagination cursors after a refresh', () async {
      final radarr = _instance('radarr-home', InstanceType.radarr);
      final repository = MockMovieRepository();
      final stalePage = Completer<HistoryPage>();
      var pageOneCalls = 0;
      var pageTwoCalls = 0;
      when(
        () => repository.getHistory(page: 1, pageSize: 50, eventType: null),
      ).thenAnswer((_) async {
        pageOneCalls++;
        return _historyPage(
          page: 1,
          totalRecords: 2,
          records: [
            _historyEvent(
              100 + pageOneCalls,
              DateTime.utc(2026, 1, pageOneCalls),
            ),
          ],
        );
      });
      when(
        () => repository.getHistory(page: 2, pageSize: 50, eventType: null),
      ).thenAnswer((_) {
        pageTwoCalls++;
        if (pageTwoCalls == 1) {
          return stalePage.future;
        }
        return Future.value(
          _historyPage(
            page: 2,
            totalRecords: 2,
            records: [_historyEvent(3, DateTime.utc(2026, 1, 3))],
          ),
        );
      });
      final container = _container(
        radarrInstances: [radarr],
        sonarrInstances: const [],
        movieRepositories: {radarr: repository},
        seriesRepositories: const {},
      );
      addTearDown(container.dispose);
      await container.read(activityHistoryProvider.future);

      final staleLoad = container
          .read(activityHistoryProvider.notifier)
          .loadMore();
      await Future<void>.delayed(Duration.zero);
      await container.read(activityHistoryProvider.notifier).refresh();
      stalePage.complete(
        _historyPage(
          page: 2,
          totalRecords: 2,
          records: [_historyEvent(99, DateTime.utc(2026, 1, 4))],
        ),
      );
      await staleLoad;
      await container.read(activityHistoryProvider.notifier).loadMore();

      expect(pageOneCalls, greaterThanOrEqualTo(2));
      expect(pageTwoCalls, 2);
      final eventIds = container
          .read(activityHistoryProvider)
          .value!
          .map((event) => event.id);
      expect(eventIds, contains(3));
      expect(eventIds, isNot(contains(99)));
    });

    test(
      'should preserve failures for instances skipped while loading more',
      () async {
        final failedRadarr = _instance('radarr-offline', InstanceType.radarr);
        final healthyRadarr = _instance('radarr-home', InstanceType.radarr);
        final failedRepository = MockMovieRepository();
        final healthyRepository = MockMovieRepository();
        when(
          () => failedRepository.getHistory(
            page: 1,
            pageSize: 50,
            eventType: null,
          ),
        ).thenThrow(StateError('offline'));
        _stubHistoryPage(
          healthyRepository,
          page: 1,
          result: _historyPage(
            page: 1,
            totalRecords: 2,
            records: [_historyEvent(1, DateTime.utc(2026, 1, 1))],
          ),
        );
        _stubHistoryPage(
          healthyRepository,
          page: 2,
          result: _historyPage(
            page: 2,
            totalRecords: 2,
            records: [_historyEvent(2, DateTime.utc(2026, 1, 2))],
          ),
        );
        final container = _container(
          radarrInstances: [failedRadarr, healthyRadarr],
          sonarrInstances: const [],
          movieRepositories: {
            failedRadarr: failedRepository,
            healthyRadarr: healthyRepository,
          },
          seriesRepositories: const {},
        );
        addTearDown(container.dispose);
        await container.read(activityHistoryProvider.future);

        await container.read(activityHistoryProvider.notifier).loadMore();

        expect(
          container
              .read(historyFailuresProvider)
              .map((failure) => failure.instanceId),
          [failedRadarr.id],
        );
      },
    );
  });
}

ProviderContainer _container({
  required List<Instance> radarrInstances,
  required List<Instance> sonarrInstances,
  required Map<Instance, MovieRepository> movieRepositories,
  required Map<Instance, SeriesRepository> seriesRepositories,
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

HistoryEvent _historyEvent(int id, DateTime date) {
  return HistoryEvent.fromJson({
    'id': id,
    'eventType': 'grabbed',
    'date': date.toIso8601String(),
    'sourceTitle': 'Event $id',
    'movieId': id,
    'quality': {
      'quality': {'id': 1, 'name': '1080p'},
      'revision': {'version': 1, 'real': 0},
    },
  });
}

HistoryPage _historyPage({
  required int page,
  required List<HistoryEvent> records,
  int? totalRecords,
}) {
  return HistoryPage(
    page: page,
    pageSize: 1,
    totalRecords: totalRecords ?? records.length,
    records: records,
  );
}

void _stubHistoryPage(
  MockMovieRepository repository, {
  required int page,
  required HistoryPage result,
}) {
  when(
    () => repository.getHistory(page: page, pageSize: 50, eventType: null),
  ).thenAnswer((_) async => result);
}

void _stubSeriesHistoryPage(
  MockSeriesRepository repository, {
  required int page,
  required HistoryPage result,
}) {
  when(
    () => repository.getHistory(page: page, pageSize: 50, eventType: null),
  ).thenAnswer((_) async => result);
}
