import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/activity_provider.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  late MockMovieRepository mockMovieRepo;
  late MockSeriesRepository mockSeriesRepo;

  setUp(() {
    mockMovieRepo = MockMovieRepository();
    mockSeriesRepo = MockSeriesRepository();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(mockMovieRepo),
        seriesRepositoryProvider.overrideWithValue(mockSeriesRepo),
      ],
    );
  }

  group('QueueNotifier removal', () {
    test(
      'Deve parar no primeiro repositório se a remoção for bem-sucedida',
      () async {
        // Given
        final container = createContainer();
        final notifier = container.read(queueProvider.notifier);

        when(() => mockMovieRepo.getQueue()).thenAnswer(
          (_) async => const QueueItems(
            records: [],
            totalRecords: 0,
            page: 1,
            pageSize: 25,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
          ),
        );
        when(() => mockSeriesRepo.getQueue()).thenAnswer(
          (_) async => const QueueItems(
            records: [],
            totalRecords: 0,
            page: 1,
            pageSize: 25,
            sortKey: 'timeleft',
            sortDirection: 'ascending',
          ),
        );

        when(
          () => mockMovieRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        ).thenAnswer((_) async {});

        // When
        await notifier.removeQueueItem(123, blocklist: true);

        // Then
        verify(
          () => mockMovieRepo.deleteQueueItem(
            123,
            removeFromClient: true,
            blocklist: true,
            skipRedownload: false,
          ),
        ).called(1);

        verifyNever(
          () => mockSeriesRepo.deleteQueueItem(
            any(),
            removeFromClient: any(named: 'removeFromClient'),
            blocklist: any(named: 'blocklist'),
            skipRedownload: any(named: 'skipRedownload'),
          ),
        );

        verify(() => mockMovieRepo.getQueue()).called(greaterThan(0));
      },
    );

    test('Deve tentar no segundo repositório se o primeiro falhar', () async {
      // Given
      final container = createContainer();
      final notifier = container.read(queueProvider.notifier);

      when(() => mockMovieRepo.getQueue()).thenAnswer(
        (_) async => const QueueItems(
          records: [],
          totalRecords: 0,
          page: 1,
          pageSize: 25,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
        ),
      );
      when(() => mockSeriesRepo.getQueue()).thenAnswer(
        (_) async => const QueueItems(
          records: [],
          totalRecords: 0,
          page: 1,
          pageSize: 25,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
        ),
      );

      when(
        () => mockMovieRepo.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenThrow(Exception('Not found in Radarr'));

      when(
        () => mockSeriesRepo.deleteQueueItem(
          any(),
          removeFromClient: any(named: 'removeFromClient'),
          blocklist: any(named: 'blocklist'),
          skipRedownload: any(named: 'skipRedownload'),
        ),
      ).thenAnswer((_) async {});

      // When
      await notifier.removeQueueItem(456);

      // Then
      verify(
        () => mockMovieRepo.deleteQueueItem(
          456,
          removeFromClient: true,
          blocklist: false,
          skipRedownload: false,
        ),
      ).called(1);

      verify(
        () => mockSeriesRepo.deleteQueueItem(
          456,
          removeFromClient: true,
          blocklist: false,
          skipRedownload: false,
        ),
      ).called(1);

      verify(() => mockSeriesRepo.getQueue()).called(greaterThan(0));
    });
  });
}
