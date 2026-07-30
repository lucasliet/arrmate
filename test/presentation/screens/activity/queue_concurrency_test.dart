import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/activity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

final _queueInstancesProvider = StateProvider<List<Instance>>(
  (ref) => const [],
);

void main() {
  group('QueueNotifier single-flight', () {
    testWidgets(
      'should drop polling ticks while the initial fetch is running',
      (tester) async {
        final radarr = _instance('radarr');
        final repository = MockMovieRepository();
        final buildGate = Completer<QueueItems>();
        var callCount = 0;
        when(() => repository.getQueue(page: 1, pageSize: 100)).thenAnswer((_) {
          callCount++;
          return buildGate.future;
        });
        final container = _container(radarr, repository);
        addTearDown(container.dispose);

        final buildFuture = container.read(queueProvider.future);
        await tester.pump(const Duration(seconds: 6));
        buildGate.complete(
          _queuePage(records: [_queueItem(id: 1)], totalRecords: 1),
        );
        await buildFuture;

        expect(callCount, 1);
      },
    );

    test(
      'should coalesce a refresh requested during the initial build',
      () async {
        final radarr = _instance('radarr');
        final repository = MockMovieRepository();
        final buildGate = Completer<QueueItems>();
        final refreshGate = Completer<QueueItems>();
        var callCount = 0;
        when(() => repository.getQueue(page: 1, pageSize: 100)).thenAnswer((_) {
          callCount++;
          return callCount == 1 ? buildGate.future : refreshGate.future;
        });
        final container = _container(radarr, repository);
        addTearDown(container.dispose);

        final buildFuture = container.read(queueProvider.future);
        final refreshFuture = container.read(queueProvider.notifier).refresh();

        expect(callCount, 1);
        buildGate.complete(
          _queuePage(records: [_queueItem(id: 1)], totalRecords: 1),
        );
        refreshGate.complete(
          _queuePage(records: [_queueItem(id: 2)], totalRecords: 1),
        );
        final items = await buildFuture;
        await refreshFuture;

        expect(callCount, 2);
        expect(items.single.id, 2);
      },
    );

    test(
      'should coalesce concurrent refreshes and keep the newest result',
      () async {
        final radarr = _instance('radarr');
        final repository = MockMovieRepository();

        final buildGate = Completer<QueueItems>();
        final firstGate = Completer<QueueItems>();
        final secondGate = Completer<QueueItems>();

        var callCount = 0;
        when(() => repository.getQueue(page: 1, pageSize: 100)).thenAnswer((_) {
          callCount++;
          switch (callCount) {
            case 1:
              return buildGate.future;
            case 2:
              return firstGate.future;
            default:
              return secondGate.future;
          }
        });

        final container = _container(radarr, repository);
        addTearDown(container.dispose);

        buildGate.complete(_queuePage(records: [], totalRecords: 0));
        await container.read(queueProvider.future);

        final firstRefresh = container.read(queueProvider.notifier).refresh();
        container.read(queueProvider.notifier).refresh();

        firstGate.complete(
          _queuePage(records: [_queueItem(id: 1)], totalRecords: 1),
        );

        secondGate.complete(
          _queuePage(records: [_queueItem(id: 2)], totalRecords: 1),
        );

        await firstRefresh;
        await container.read(queueProvider.future);

        final items = container.read(queueProvider).valueOrNull ?? [];
        expect(items.length, 1);
        expect(items.first.id, 2);
      },
    );

    test('should deduplicate overlapping pages by queue item id', () async {
      final radarr = _instance('radarr');
      final repository = MockMovieRepository();
      when(() => repository.getQueue(page: 1, pageSize: 100)).thenAnswer(
        (_) async => _queuePage(
          records: [_queueItem(id: 1), _queueItem(id: 2)],
          totalRecords: 3,
        ),
      );
      when(() => repository.getQueue(page: 2, pageSize: 100)).thenAnswer(
        (_) async => _queuePage(
          records: [_queueItem(id: 2), _queueItem(id: 3)],
          totalRecords: 3,
        ),
      );
      final container = _container(radarr, repository);
      addTearDown(container.dispose);

      final items = await container.read(queueProvider.future);

      expect(items.map((item) => item.id), [1, 2, 3]);
      verify(() => repository.getQueue(page: 1, pageSize: 100)).called(1);
      verify(() => repository.getQueue(page: 2, pageSize: 100)).called(1);
      verifyNever(() => repository.getQueue(page: 3, pageSize: 100));
    });

    test('should ignore failures from a stale dependency generation', () async {
      final first = _instance('first');
      final second = _instance('second');
      final firstRepository = MockMovieRepository();
      final secondRepository = MockMovieRepository();
      final staleGate = Completer<QueueItems>();
      when(
        () => firstRepository.getQueue(page: 1, pageSize: 100),
      ).thenAnswer((_) => staleGate.future);
      when(() => secondRepository.getQueue(page: 1, pageSize: 100)).thenAnswer(
        (_) async => _queuePage(records: [_queueItem(id: 2)], totalRecords: 1),
      );
      final container = ProviderContainer(
        overrides: [
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWith((ref) => ref.watch(_queueInstancesProvider)),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue(const []),
          movieRepositoryForInstanceProvider(
            first,
          ).overrideWithValue(firstRepository),
          movieRepositoryForInstanceProvider(
            second,
          ).overrideWithValue(secondRepository),
        ],
      );
      final subscription = container.listen(queueProvider, (_, _) {});
      addTearDown(subscription.close);
      addTearDown(container.dispose);
      container.read(_queueInstancesProvider.notifier).state = [first];
      final staleFuture = container.read(queueProvider.future);
      await Future<void>.delayed(Duration.zero);

      container.read(_queueInstancesProvider.notifier).state = [second];
      final currentItems = await container.read(queueProvider.future);
      staleGate.completeError(StateError('stale offline instance'));
      await staleFuture;
      await Future<void>.delayed(Duration.zero);

      expect(currentItems.single.id, 2);
      expect(container.read(queueProvider).value!.single.id, 2);
      expect(container.read(queueFailuresProvider), isEmpty);
    });

    test(
      'should wait for the current generation when instances change',
      () async {
        final first = _instance('first');
        final second = _instance('second');
        final firstRepository = MockMovieRepository();
        final secondRepository = MockMovieRepository();
        final firstGenerationGate = Completer<QueueItems>();
        final secondGenerationGate = Completer<QueueItems>();
        when(
          () => firstRepository.getQueue(page: 1, pageSize: 100),
        ).thenAnswer((_) => firstGenerationGate.future);
        when(
          () => secondRepository.getQueue(page: 1, pageSize: 100),
        ).thenAnswer((_) => secondGenerationGate.future);
        final container = ProviderContainer(
          overrides: [
            instancesByTypeProvider(
              InstanceType.radarr,
            ).overrideWith((ref) => ref.watch(_queueInstancesProvider)),
            instancesByTypeProvider(
              InstanceType.sonarr,
            ).overrideWithValue(const []),
            movieRepositoryForInstanceProvider(
              first,
            ).overrideWithValue(firstRepository),
            movieRepositoryForInstanceProvider(
              second,
            ).overrideWithValue(secondRepository),
          ],
        );
        container.read(_queueInstancesProvider.notifier).state = [first];
        final subscription = container.listen(queueProvider, (_, _) {});
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        container.read(queueProvider.future);
        await Future<void>.delayed(Duration.zero);
        var refreshCompleted = false;
        final refreshFuture = container
            .read(queueProvider.notifier)
            .refresh()
            .whenComplete(() => refreshCompleted = true);

        container.read(_queueInstancesProvider.notifier).state = [second];
        final currentGenerationFuture = container.read(queueProvider.future);
        await Future<void>.delayed(Duration.zero);
        firstGenerationGate.complete(
          _queuePage(records: [_queueItem(id: 1)], totalRecords: 1),
        );
        await Future<void>.delayed(Duration.zero);

        expect(refreshCompleted, isFalse);

        secondGenerationGate.complete(
          _queuePage(records: [_queueItem(id: 2)], totalRecords: 1),
        );
        final currentItems = await currentGenerationFuture;
        await refreshFuture;

        expect(refreshCompleted, isTrue);
        expect(currentItems.single.id, 2);
      },
    );

    test(
      'should release the old cycle when the current generation finishes first',
      () async {
        final first = _instance('first');
        final second = _instance('second');
        final firstRepository = MockMovieRepository();
        final secondRepository = MockMovieRepository();
        final firstGenerationGate = Completer<QueueItems>();
        final secondGenerationGate = Completer<QueueItems>();
        when(
          () => firstRepository.getQueue(page: 1, pageSize: 100),
        ).thenAnswer((_) => firstGenerationGate.future);
        when(
          () => secondRepository.getQueue(page: 1, pageSize: 100),
        ).thenAnswer((_) => secondGenerationGate.future);
        final container = ProviderContainer(
          overrides: [
            instancesByTypeProvider(
              InstanceType.radarr,
            ).overrideWith((ref) => ref.watch(_queueInstancesProvider)),
            instancesByTypeProvider(
              InstanceType.sonarr,
            ).overrideWithValue(const []),
            movieRepositoryForInstanceProvider(
              first,
            ).overrideWithValue(firstRepository),
            movieRepositoryForInstanceProvider(
              second,
            ).overrideWithValue(secondRepository),
          ],
        );
        container.read(_queueInstancesProvider.notifier).state = [first];
        final subscription = container.listen(queueProvider, (_, _) {});
        addTearDown(subscription.close);
        addTearDown(container.dispose);
        container.read(queueProvider.future);
        await Future<void>.delayed(Duration.zero);
        var refreshCompleted = false;
        final refreshFuture = container
            .read(queueProvider.notifier)
            .refresh()
            .whenComplete(() => refreshCompleted = true);

        container.read(_queueInstancesProvider.notifier).state = [second];
        final currentGenerationFuture = container.read(queueProvider.future);
        await Future<void>.delayed(Duration.zero);
        secondGenerationGate.complete(
          _queuePage(records: [_queueItem(id: 2)], totalRecords: 1),
        );
        final currentItems = await currentGenerationFuture;
        await refreshFuture;

        expect(refreshCompleted, isTrue);
        expect(firstGenerationGate.isCompleted, isFalse);
        expect(currentItems.single.id, 2);

        firstGenerationGate.complete(
          _queuePage(records: [_queueItem(id: 1)], totalRecords: 1),
        );
        await Future<void>.delayed(Duration.zero);

        expect(container.read(queueProvider).value!.single.id, 2);
      },
    );
  });
}

ProviderContainer _container(Instance radarr, MovieRepository repository) {
  return ProviderContainer(
    overrides: [
      instancesByTypeProvider(InstanceType.radarr).overrideWithValue([radarr]),
      instancesByTypeProvider(InstanceType.sonarr).overrideWithValue(const []),
      movieRepositoryForInstanceProvider(radarr).overrideWithValue(repository),
    ],
  );
}

Instance _instance(String id) {
  return Instance(
    id: id,
    type: InstanceType.radarr,
    label: id,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

QueueItem _queueItem({required int id}) {
  return QueueItem(
    id: id,
    title: 'Queue item $id',
    status: QueueStatus.downloading,
    protocol: 'torrent',
    sizeleft: 1,
  );
}

QueueItems _queuePage({
  required List<QueueItem> records,
  required int totalRecords,
}) {
  return QueueItems(
    records: records,
    totalRecords: totalRecords,
    page: 1,
    pageSize: 100,
    sortKey: 'timeleft',
    sortDirection: 'ascending',
  );
}
