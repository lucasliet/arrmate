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

void main() {
  group('QueueNotifier single-flight', () {
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
