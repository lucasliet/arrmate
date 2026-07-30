import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/advanced_providers.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LogsNotifier', () {
    test(
      'should fetch first page from Radarr when a movie repository is configured',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        when(
          () => movieRepo.getLogs(page: 1),
        ).thenAnswer((_) async => _logPage(page: 1, records: ['log-a']));

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);

        // When
        final page = await container.read(logsProvider.future);

        // Then
        expect(page.records.map((e) => e.message), ['log-a']);
        verify(() => movieRepo.getLogs(page: 1)).called(1);
      },
    );

    test(
      'should fall back to the series repository when only Sonarr is configured',
      () async {
        // Given
        final seriesRepo = MockSeriesRepository();
        when(
          () => seriesRepo.getLogs(page: 1),
        ).thenAnswer((_) async => _logPage(page: 1, records: ['log-b']));

        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(seriesRepo)],
        );
        addTearDown(container.dispose);

        // When
        final page = await container.read(logsProvider.future);

        // Then
        expect(page.records.map((e) => e.message), ['log-b']);
        verify(() => seriesRepo.getLogs(page: 1)).called(1);
      },
    );

    test(
      'should return an empty default page when no instance is configured',
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
        final page = await container.read(logsProvider.future);

        // Then
        expect(page.records, isEmpty);
        expect(page.totalRecords, 0);
      },
    );

    test(
      'should append next page records when fetchNextPage is called',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        when(() => movieRepo.getLogs(page: 1)).thenAnswer(
          (_) async => _logPage(page: 1, totalRecords: 120, records: ['log-1']),
        );
        when(() => movieRepo.getLogs(page: 2)).thenAnswer(
          (_) async =>
              _logPage(page: 2, totalRecords: 120, records: ['log-2', 'log-3']),
        );

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);
        await container.read(logsProvider.future);

        // When
        await container.read(logsProvider.notifier).fetchNextPage();

        // Then
        final page = container.read(logsProvider).value!;
        expect(page.records.map((e) => e.message), ['log-1', 'log-2', 'log-3']);
        verify(() => movieRepo.getLogs(page: 2)).called(1);
      },
    );

    test('should not fetch beyond the last page', () async {
      // Given
      final movieRepo = MockMovieRepository();
      when(() => movieRepo.getLogs(page: 1)).thenAnswer(
        (_) async => _logPage(page: 1, totalRecords: 40, records: ['log-1']),
      );

      final container = ProviderContainer(
        overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
      );
      addTearDown(container.dispose);
      await container.read(logsProvider.future);

      // When
      await container.read(logsProvider.notifier).fetchNextPage();

      // Then
      verifyNever(() => movieRepo.getLogs(page: 2));
    });

    test(
      'should honor a custom page size when deciding whether to paginate',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        when(() => movieRepo.getLogs(page: 1)).thenAnswer(
          (_) async => _logPage(
            page: 1,
            pageSize: 25,
            totalRecords: 40,
            records: ['log-1'],
          ),
        );
        when(() => movieRepo.getLogs(page: 2)).thenAnswer(
          (_) async => _logPage(
            page: 2,
            pageSize: 25,
            totalRecords: 40,
            records: ['log-2'],
          ),
        );

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);
        await container.read(logsProvider.future);

        // When
        await container.read(logsProvider.notifier).fetchNextPage();

        // Then
        final page = container.read(logsProvider).value!;
        expect(page.records.map((e) => e.message), ['log-1', 'log-2']);
        verify(() => movieRepo.getLogs(page: 2)).called(1);
      },
    );

    test(
      'should ignore overlapping scroll-driven pagination requests',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        when(() => movieRepo.getLogs(page: 1)).thenAnswer(
          (_) async => _logPage(page: 1, totalRecords: 120, records: ['log-1']),
        );
        final pageTwoCompleter = Completer<LogPage>();
        when(
          () => movieRepo.getLogs(page: 2),
        ).thenAnswer((_) => pageTwoCompleter.future);

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);
        await container.read(logsProvider.future);

        // When
        final firstCall = container.read(logsProvider.notifier).fetchNextPage();
        await container.read(logsProvider.notifier).fetchNextPage();
        pageTwoCompleter.complete(
          _logPage(page: 2, totalRecords: 120, records: ['log-2']),
        );
        await firstCall;

        // Then
        verify(() => movieRepo.getLogs(page: 2)).called(1);
        final page = container.read(logsProvider).value!;
        expect(page.records.map((e) => e.message), ['log-1', 'log-2']);
      },
    );

    test(
      'should discard a late page response after the log source switches',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        final seriesRepo = MockSeriesRepository();
        when(() => movieRepo.getLogs(page: 1)).thenAnswer(
          (_) async =>
              _logPage(page: 1, totalRecords: 120, records: ['log-r1']),
        );
        final radarrPageTwo = Completer<LogPage>();
        when(
          () => movieRepo.getLogs(page: 2),
        ).thenAnswer((_) => radarrPageTwo.future);
        when(() => seriesRepo.getLogs(page: 1)).thenAnswer(
          (_) async => _logPage(page: 1, totalRecords: 30, records: ['log-s1']),
        );

        final container = ProviderContainer(
          overrides: [
            movieRepositoryProvider.overrideWithValue(movieRepo),
            seriesRepositoryProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);
        await container.read(logsProvider.future);

        // When
        final radarrFetch = container
            .read(logsProvider.notifier)
            .fetchNextPage();
        container.updateOverrides([
          movieRepositoryProvider.overrideWithValue(null),
          seriesRepositoryProvider.overrideWithValue(seriesRepo),
        ]);
        await container.read(logsProvider.future);
        radarrPageTwo.complete(
          _logPage(page: 2, totalRecords: 120, records: ['log-r2']),
        );
        await radarrFetch;

        // Then
        final page = container.read(logsProvider).value!;
        expect(page.records.map((e) => e.message), isNot(contains('log-r2')));
      },
    );

    test(
      'should preserve previous records when the next page fails to load',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        when(() => movieRepo.getLogs(page: 1)).thenAnswer(
          (_) async => _logPage(page: 1, totalRecords: 120, records: ['log-1']),
        );
        when(() => movieRepo.getLogs(page: 2)).thenThrow(Exception('boom'));

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);
        await container.read(logsProvider.future);

        // When
        await container.read(logsProvider.notifier).fetchNextPage();

        // Then
        final status = container.read(logsProvider);
        expect(status.hasError, isTrue);
        expect(status.isLoading, isFalse);
        expect(status.value?.records.map((e) => e.message), ['log-1']);
      },
    );
  });

  group('Quality profile providers', () {
    test(
      'should return movie quality profiles when a movie repository is configured',
      () async {
        // Given
        final movieRepo = MockMovieRepository();
        const profile = QualityProfile(id: 1, name: 'HD');
        when(movieRepo.getQualityProfiles).thenAnswer((_) async => [profile]);

        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(movieRepo)],
        );
        addTearDown(container.dispose);

        // When
        final profiles = await container.read(
          movieQualityProfilesProvider.future,
        );

        // Then
        expect(profiles, [profile]);
      },
    );

    test(
      'should return an empty list when no movie repository is configured',
      () async {
        // Given
        final container = ProviderContainer(
          overrides: [movieRepositoryProvider.overrideWithValue(null)],
        );
        addTearDown(container.dispose);

        // When
        final profiles = await container.read(
          movieQualityProfilesProvider.future,
        );

        // Then
        expect(profiles, isEmpty);
      },
    );

    test(
      'should return series quality profiles when a series repository is configured',
      () async {
        // Given
        final seriesRepo = MockSeriesRepository();
        const profile = QualityProfile(id: 2, name: '4K');
        when(seriesRepo.getQualityProfiles).thenAnswer((_) async => [profile]);

        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(seriesRepo)],
        );
        addTearDown(container.dispose);

        // When
        final profiles = await container.read(
          seriesQualityProfilesProvider.future,
        );

        // Then
        expect(profiles, [profile]);
      },
    );
  });
}

LogPage _logPage({
  required int page,
  int pageSize = 50,
  int totalRecords = 0,
  List<String> records = const [],
}) {
  return LogPage(
    page: page,
    pageSize: pageSize,
    totalRecords: totalRecords,
    records: [
      for (final message in records)
        LogEntry(
          time: DateTime.utc(2024, 1, page),
          level: 'info',
          logger: 'test',
          message: message,
        ),
    ],
  );
}
