import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/advanced_providers.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

final _selectedMovieRepositoryProvider = StateProvider<MovieRepository?>(
  (ref) => null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthNotifier', () {
    test(
      'should preserve server checks when another service cannot be reached',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        final seriesRepository = MockSeriesRepository();
        const movieWarning = HealthCheck(
          source: 'Indexer',
          type: 'warning',
          message: 'Indexer is unavailable',
          wikiUrl: '',
        );
        when(movieRepository.getHealth).thenAnswer((_) async => [movieWarning]);
        when(
          seriesRepository.getHealth,
        ).thenThrow(StateError('connection failed'));
        final container = ProviderContainer(
          overrides: [
            movieRepositoryProvider.overrideWithValue(movieRepository),
            seriesRepositoryProvider.overrideWithValue(seriesRepository),
          ],
        );
        addTearDown(container.dispose);

        // When
        final overview = await container.read(healthProvider.future);

        // Then
        expect(overview.configuredSourceCount, 2);
        expect(overview.serverChecks, [movieWarning]);
        expect(overview.connectionFailures, hasLength(1));
        expect(overview.connectionFailures.single.service, 'Sonarr');
        expect(
          overview.connectionFailures.single.operation,
          HealthConnectionOperation.loadStatus,
        );
      },
    );

    test(
      'should expose every connection failure when all services fail',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        final seriesRepository = MockSeriesRepository();
        when(movieRepository.getHealth).thenThrow(StateError('radarr failed'));
        when(seriesRepository.getHealth).thenThrow(StateError('sonarr failed'));
        final container = ProviderContainer(
          overrides: [
            movieRepositoryProvider.overrideWithValue(movieRepository),
            seriesRepositoryProvider.overrideWithValue(seriesRepository),
          ],
        );
        addTearDown(container.dispose);

        // When
        final overview = await container.read(healthProvider.future);

        // Then
        expect(overview.configuredSourceCount, 2);
        expect(overview.serverChecks, isEmpty);
        expect(
          overview.connectionFailures.map((failure) => failure.service),
          containsAll(['Radarr', 'Sonarr']),
        );
      },
    );

    test(
      'should report no configured sources without Arr repositories',
      () async {
        // Given
        final container = ProviderContainer(
          overrides: [
            movieRepositoryProvider.overrideWithValue(null),
            seriesRepositoryProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        // When
        final overview = await container.read(healthProvider.future);

        // Then
        expect(overview.configuredSourceCount, 0);
        expect(overview.serverChecks, isEmpty);
        expect(overview.connectionFailures, isEmpty);
      },
    );

    test(
      'should preserve loaded status when starting a new check fails',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        const movieWarning = HealthCheck(
          source: 'Download client',
          type: 'warning',
          message: 'Download client is unavailable',
          wikiUrl: '',
        );
        when(movieRepository.getHealth).thenAnswer((_) async => [movieWarning]);
        when(
          movieRepository.healthCheck,
        ).thenThrow(StateError('command failed'));
        final container = ProviderContainer(
          overrides: [
            movieRepositoryProvider.overrideWithValue(movieRepository),
            seriesRepositoryProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await container.read(healthProvider.future);

        // When
        await container.read(healthProvider.notifier).runHealthChecks();

        // Then
        final overview = container.read(healthProvider).requireValue;
        expect(overview.serverChecks, [movieWarning]);
        expect(overview.connectionFailures, hasLength(1));
        expect(
          overview.connectionFailures.single.operation,
          HealthConnectionOperation.runCheck,
        );
      },
    );

    test(
      'should test the indexers before the health check when they are in backoff',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        final calls = <String>[];
        when(
          movieRepository.getHealth,
        ).thenAnswer((_) async => [_check('IndexerLongTermStatusCheck')]);
        when(movieRepository.testAllIndexers).thenAnswer((_) async {
          calls.add('testAllIndexers');
        });
        when(movieRepository.healthCheck).thenAnswer((_) async {
          calls.add('healthCheck');
        });
        final container = _container(movieRepository: movieRepository);
        addTearDown(container.dispose);
        await container.read(healthProvider.future);

        // When
        await container.read(healthProvider.notifier).runHealthChecks();

        // Then
        expect(calls, ['testAllIndexers', 'healthCheck']);
        verifyNever(movieRepository.testAllDownloadClients);
      },
    );

    test('should test the download clients when they are in backoff', () async {
      // Given
      final seriesRepository = MockSeriesRepository();
      when(
        seriesRepository.getHealth,
      ).thenAnswer((_) async => [_check('DownloadClientStatusCheck')]);
      when(seriesRepository.testAllDownloadClients).thenAnswer((_) async {});
      when(seriesRepository.healthCheck).thenAnswer((_) async {});
      final container = _container(seriesRepository: seriesRepository);
      addTearDown(container.dispose);
      await container.read(healthProvider.future);

      // When
      await container.read(healthProvider.notifier).runHealthChecks();

      // Then
      verify(seriesRepository.testAllDownloadClients).called(1);
      verifyNever(seriesRepository.testAllIndexers);
    });

    test(
      'should still run the health check when an indexer keeps failing its test',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        final indexerWarning = _check('IndexerStatusCheck');
        when(
          movieRepository.getHealth,
        ).thenAnswer((_) async => [indexerWarning]);
        when(
          movieRepository.testAllIndexers,
        ).thenThrow(StateError('indexer test failed'));
        when(movieRepository.healthCheck).thenAnswer((_) async {});
        final container = _container(movieRepository: movieRepository);
        addTearDown(container.dispose);
        await container.read(healthProvider.future);

        // When
        await container.read(healthProvider.notifier).runHealthChecks();

        // Then
        verify(movieRepository.healthCheck).called(1);
        final overview = container.read(healthProvider).requireValue;
        expect(overview.serverChecks, [indexerWarning]);
        expect(overview.connectionFailures, isEmpty);
      },
    );

    test(
      'should not test providers when no indexer or download client is failing',
      () async {
        // Given
        final movieRepository = MockMovieRepository();
        when(
          movieRepository.getHealth,
        ).thenAnswer((_) async => [_check('AllowedHostsCheck')]);
        when(movieRepository.healthCheck).thenAnswer((_) async {});
        final container = _container(movieRepository: movieRepository);
        addTearDown(container.dispose);
        await container.read(healthProvider.future);

        // When
        await container.read(healthProvider.notifier).runHealthChecks();

        // Then
        verify(movieRepository.healthCheck).called(1);
        verifyNever(movieRepository.testAllIndexers);
        verifyNever(movieRepository.testAllDownloadClients);
      },
    );

    test(
      'should discard an in-flight refresh after the repository changes',
      () async {
        // Given
        final oldRepository = MockMovieRepository();
        final currentRepository = MockMovieRepository();
        final oldCommand = Completer<void>();
        final currentHealth = Completer<List<HealthCheck>>();
        const currentWarning = HealthCheck(
          source: 'Current indexer',
          type: 'warning',
          message: 'Current repository result',
          wikiUrl: '',
        );
        when(oldRepository.getHealth).thenAnswer((_) async => []);
        when(oldRepository.healthCheck).thenAnswer((_) => oldCommand.future);
        when(
          currentRepository.getHealth,
        ).thenAnswer((_) => currentHealth.future);
        final container = ProviderContainer(
          overrides: [
            _selectedMovieRepositoryProvider.overrideWith(
              (ref) => oldRepository,
            ),
            movieRepositoryProvider.overrideWith(
              (ref) => ref.watch(_selectedMovieRepositoryProvider),
            ),
            seriesRepositoryProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await container.read(healthProvider.future);
        final staleRefresh = container
            .read(healthProvider.notifier)
            .runHealthChecks();

        // When
        container.read(_selectedMovieRepositoryProvider.notifier).state =
            currentRepository;
        final currentResult = container.read(healthProvider.future);
        currentHealth.complete([currentWarning]);
        await currentResult;
        oldCommand.complete();
        await staleRefresh;

        // Then
        final overview = container.read(healthProvider).requireValue;
        expect(overview.serverChecks, [currentWarning]);
        expect(overview.connectionFailures, isEmpty);
        verify(oldRepository.getHealth).called(1);
      },
    );
  });
}

HealthCheck _check(String source) {
  return HealthCheck(
    source: source,
    type: 'warning',
    message: '$source message',
    wikiUrl: '',
  );
}

ProviderContainer _container({
  MovieRepository? movieRepository,
  SeriesRepository? seriesRepository,
}) {
  return ProviderContainer(
    overrides: [
      movieRepositoryProvider.overrideWithValue(movieRepository),
      seriesRepositoryProvider.overrideWithValue(seriesRepository),
    ],
  );
}
