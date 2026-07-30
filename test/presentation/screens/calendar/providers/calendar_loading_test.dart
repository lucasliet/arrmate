import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMovieRepository extends Mock implements MovieRepository {}

final _mutableCalendarNowProvider = StateProvider<DateTime>(
  (ref) => DateTime.utc(2026, 7, 29),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar range loading', () {
    test('should keep successful data and expose failed instances', () async {
      // Given
      final home = _instance('home', 'Home');
      final remote = _instance('remote', 'Remote');
      final homeRepository = _MockMovieRepository();
      final remoteRepository = _MockMovieRepository();
      final now = DateTime.utc(2026, 7, 29);
      when(
        () => homeRepository.getCalendar(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => [_movie(1, now.add(const Duration(days: 1)))]);
      when(
        () => remoteRepository.getCalendar(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenThrow(StateError('offline'));
      final container = ProviderContainer(
        overrides: [
          calendarNowProvider.overrideWithValue(now),
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWithValue([home, remote]),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue(const []),
          movieRepositoryForInstanceProvider(
            home,
          ).overrideWithValue(homeRepository),
          movieRepositoryForInstanceProvider(
            remote,
          ).overrideWithValue(remoteRepository),
        ],
      );
      final subscription = container.listen(calendarProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(container.dispose);

      // When
      final events = await container.read(calendarProvider.future);
      final status = container.read(calendarLoadStatusProvider);

      // Then
      expect(events, hasLength(1));
      expect(events.single.instanceId, home.id);
      expect(status.failures, [
        CalendarInstanceFailure(
          instanceId: remote.id,
          instanceType: remote.type,
          instanceLabel: remote.label,
          message: 'Calendar data could not be loaded.',
        ),
      ]);
    });

    test('should load future ranges and deduplicate boundary events', () async {
      // Given
      final instance = _instance('home', 'Home');
      final repository = _MockMovieRepository();
      final now = DateTime.utc(2026, 7, 29);
      final initialEnd = now.add(const Duration(days: 45));
      final starts = <DateTime>[];
      var requestCount = 0;
      when(
        () => repository.getCalendar(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((invocation) async {
        starts.add(invocation.namedArguments[#start]! as DateTime);
        requestCount++;
        if (requestCount == 1) {
          return [_movie(1, initialEnd)];
        }
        return [
          _movie(1, initialEnd),
          _movie(2, initialEnd.add(const Duration(days: 1))),
        ];
      });
      final container = ProviderContainer(
        overrides: [
          calendarNowProvider.overrideWithValue(now),
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWithValue([instance]),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue(const []),
          movieRepositoryForInstanceProvider(
            instance,
          ).overrideWithValue(repository),
        ],
      );
      final subscription = container.listen(calendarProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      await container.read(calendarProvider.future);

      // When
      await container.read(calendarProvider.notifier).loadMore();
      final events = container.read(calendarProvider).value!;
      final status = container.read(calendarLoadStatusProvider);

      // Then
      expect(starts, [now.subtract(const Duration(days: 7)), initialEnd]);
      expect(events.map((event) => event.movie?.guid), [1, 2]);
      expect(status.loadedEnd, now.add(const Duration(days: 90)));
      expect(status.isLoadingMore, isFalse);
    });

    test('should serialize refresh and load more requests', () async {
      // Given
      final instance = _instance('home', 'Home');
      final repository = _MockMovieRepository();
      final now = DateTime.utc(2026, 7, 29);
      final loadMoreGate = Completer<List<Movie>>();
      final refreshGate = Completer<List<Movie>>();
      var requestCount = 0;
      when(
        () => repository.getCalendar(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) {
        requestCount++;
        switch (requestCount) {
          case 1:
            return Future.value([_movie(1, now.add(const Duration(days: 1)))]);
          case 2:
            return loadMoreGate.future;
          default:
            return refreshGate.future;
        }
      });
      final container = ProviderContainer(
        overrides: [
          calendarNowProvider.overrideWithValue(now),
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWithValue([instance]),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue(const []),
          movieRepositoryForInstanceProvider(
            instance,
          ).overrideWithValue(repository),
        ],
      );
      final subscription = container.listen(calendarProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      await container.read(calendarProvider.future);
      final notifier = container.read(calendarProvider.notifier);

      // When
      final loadMore = notifier.loadMore();
      await Future<void>.delayed(Duration.zero);
      await notifier.refresh();
      expect(requestCount, 2);
      loadMoreGate.complete([_movie(2, now.add(const Duration(days: 46)))]);
      await loadMore;
      final refresh = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      await notifier.loadMore();

      // Then
      expect(requestCount, 3);
      refreshGate.complete([
        _movie(1, now.add(const Duration(days: 1))),
        _movie(2, now.add(const Duration(days: 46))),
      ]);
      await refresh;
      expect(container.read(calendarLoadStatusProvider).isLoadingMore, isFalse);
    });

    test(
      'should not let a stale load clear the current loading flag',
      () async {
        // Given
        final instance = _instance('home', 'Home');
        final repository = _MockMovieRepository();
        final now = DateTime.utc(2026, 7, 29);
        final staleLoadGate = Completer<List<Movie>>();
        final currentLoadGate = Completer<List<Movie>>();
        var requestCount = 0;
        when(
          () => repository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) {
          requestCount++;
          switch (requestCount) {
            case 1:
              return Future.value([
                _movie(1, now.add(const Duration(days: 1))),
              ]);
            case 2:
              return staleLoadGate.future;
            case 3:
              return Future.value([
                _movie(3, now.add(const Duration(days: 2))),
              ]);
            default:
              return currentLoadGate.future;
          }
        });
        final container = ProviderContainer(
          overrides: [
            calendarNowProvider.overrideWith(
              (ref) => ref.watch(_mutableCalendarNowProvider),
            ),
            instancesByTypeProvider(
              InstanceType.radarr,
            ).overrideWithValue([instance]),
            instancesByTypeProvider(
              InstanceType.sonarr,
            ).overrideWithValue(const []),
            movieRepositoryForInstanceProvider(
              instance,
            ).overrideWithValue(repository),
          ],
        );
        final subscription = container.listen(calendarProvider, (_, _) {});
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        await container.read(calendarProvider.future);
        final notifier = container.read(calendarProvider.notifier);
        final staleLoad = notifier.loadMore();
        await Future<void>.delayed(Duration.zero);

        // When
        container.read(_mutableCalendarNowProvider.notifier).state = now.add(
          const Duration(days: 1),
        );
        await container.read(calendarProvider.future);
        final currentLoad = notifier.loadMore();
        await Future<void>.delayed(Duration.zero);
        staleLoadGate.complete([_movie(2, now.add(const Duration(days: 46)))]);
        await staleLoad;

        // Then
        expect(requestCount, 4);
        expect(
          container.read(calendarLoadStatusProvider).isLoadingMore,
          isTrue,
        );
        currentLoadGate.complete([
          _movie(4, now.add(const Duration(days: 47))),
        ]);
        await currentLoad;
        expect(
          container.read(calendarLoadStatusProvider).isLoadingMore,
          isFalse,
        );
      },
    );
  });
}

Instance _instance(String id, String label) {
  return Instance(
    id: id,
    type: InstanceType.radarr,
    label: label,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

Movie _movie(int id, DateTime releaseDate) {
  return Movie(
    guid: id,
    tmdbId: id,
    title: 'Movie $id',
    sortTitle: 'movie $id',
    year: 2026,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    added: DateTime.utc(2026),
    digitalRelease: releaseDate,
  );
}
