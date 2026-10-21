import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/shared/widgets/batch_actions_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/localized_app.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockQBittorrentService extends Mock implements QBittorrentService {}

void main() {
  testWidgets('should apply import exclusion to every selected movie', (
    tester,
  ) async {
    // Given
    final repository = MockMovieRepository();
    when(
      () => repository.deleteMovie(
        any(),
        deleteFiles: any(named: 'deleteFiles'),
        addExclusion: any(named: 'addExclusion'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [movieRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: Consumer(
            builder: (context, ref, child) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  BatchActionsHandler(
                    ref,
                  ).deleteMovies(context, [10, 20], deleteFiles: true);
                },
                child: const Text('Delete movies'),
              ),
            ),
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.text('Delete movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Then
    verify(
      () => repository.deleteMovie(10, deleteFiles: true, addExclusion: true),
    ).called(1);
    verify(
      () => repository.deleteMovie(20, deleteFiles: true, addExclusion: true),
    ).called(1);
  });

  testWidgets('should apply import exclusion to every selected series', (
    tester,
  ) async {
    // Given
    final repository = MockSeriesRepository();
    when(
      () => repository.deleteSeries(
        any(),
        deleteFiles: any(named: 'deleteFiles'),
        addExclusion: any(named: 'addExclusion'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: Consumer(
            builder: (context, ref, child) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  BatchActionsHandler(
                    ref,
                  ).deleteSeriesList(context, [30, 40], deleteFiles: false);
                },
                child: const Text('Delete series'),
              ),
            ),
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.text('Delete series'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // Then
    verify(
      () => repository.deleteSeries(30, deleteFiles: false, addExclusion: true),
    ).called(1);
    verify(
      () => repository.deleteSeries(40, deleteFiles: false, addExclusion: true),
    ).called(1);
  });

  group('batch purge with a failing item', () {
    late MockMovieRepository movies;
    late MockSeriesRepository series;
    late MockQBittorrentService qb;
    late BatchActionResult? result;

    setUp(() {
      result = null;
      movies = MockMovieRepository();
      series = MockSeriesRepository();
      qb = MockQBittorrentService();
      when(() => movies.getMovies()).thenAnswer((_) async => []);
      when(() => series.getSeries()).thenAnswer((_) async => []);
      for (final id in [1, 2, 3]) {
        when(() => movies.getMovieHistory(id)).thenAnswer((_) async => []);
        when(() => movies.getMovieFiles(id)).thenAnswer((_) async => []);
      }
      for (final id in [41, 42, 43]) {
        when(() => series.getSeriesHistory(id)).thenAnswer((_) async => []);
        when(() => series.getSeriesFiles(id)).thenAnswer((_) async => []);
      }
      _stubEmptyQueue(movies.getQueue);
      _stubEmptyQueue(series.getQueue);
      when(
        () => movies.deleteMovie(
          any(),
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => series.deleteSeries(
          any(),
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenAnswer((_) async {});
      when(qb.getTorrents).thenAnswer((_) async => []);
    });

    /// Pumps a screen that watches the movie and series lists, so a refresh of
    /// either shows up as another read of its repository, and runs [action].
    Future<void> run(
      WidgetTester tester,
      Future<BatchActionResult?> Function(
        BatchActionsHandler handler,
        BuildContext context,
      )
      action,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            movieRepositoryProvider.overrideWithValue(movies),
            seriesRepositoryProvider.overrideWithValue(series),
            qbittorrentServiceProvider.overrideWithValue(qb),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: Consumer(
              builder: (context, ref, child) {
                ref.watch(moviesProvider);
                ref.watch(seriesProvider);
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      result = await action(BatchActionsHandler(ref), context);
                    },
                    child: const Text('Purge'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Purge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    }

    testWidgets('movies: should report the partial result and refresh the '
        'list', (tester) async {
      // Given the catalog refuses the second movie
      when(
        () => movies.deleteMovie(
          2,
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenThrow(StateError('Radarr refused'));

      // When
      await run(tester, (handler, context) {
        return handler.purgeMovies(context, [1, 2, 3]);
      });

      // Then the third movie was still purged and the message says what failed
      verify(
        () => movies.deleteMovie(3, deleteFiles: true, addExclusion: false),
      ).called(1);
      expect(result!.message, startsWith('Purged 2 of 3. Failed:'));
      expect(result!.refreshCatalog, isTrue);
      // And the list was read again, so it no longer shows the purged ones
      verify(() => movies.getMovies()).called(2);
    });

    testWidgets('movies: should refresh the list when every item failed '
        'after its catalog entry was deleted', (tester) async {
      // Given movies with a download, and qBittorrent unreadable once their
      // catalog entries are gone
      for (final id in [1, 2]) {
        when(() => movies.getMovieHistory(id)).thenAnswer(
          (_) async => [_grabbed(movieId: id, downloadId: 'MOVIEHASH$id')],
        );
      }
      var reads = 0;
      when(qb.getTorrents).thenAnswer((_) async {
        reads++;
        if (reads > 4) throw StateError('qBittorrent down');
        return [];
      });

      // When
      await run(tester, (handler, context) {
        return handler.purgeMovies(context, [1, 2]);
      });

      // Then
      verify(
        () => movies.deleteMovie(1, deleteFiles: true, addExclusion: false),
      ).called(1);
      expect(result!.message, startsWith('Failed to purge:'));
      expect(result!.refreshCatalog, isTrue);
      verify(() => movies.getMovies()).called(2);
    });

    testWidgets('series: should report the partial result and refresh the '
        'list', (tester) async {
      // Given the catalog refuses the first series
      when(
        () => series.deleteSeries(
          41,
          deleteFiles: any(named: 'deleteFiles'),
          addExclusion: any(named: 'addExclusion'),
        ),
      ).thenThrow(StateError('Sonarr refused'));

      // When
      await run(tester, (handler, context) {
        return handler.purgeSeriesList(context, [41, 42, 43]);
      });

      // Then
      verify(
        () => series.deleteSeries(43, deleteFiles: true, addExclusion: false),
      ).called(1);
      expect(result!.message, startsWith('Purged 2 of 3. Failed:'));
      verify(() => series.getSeries()).called(2);
    });
  });
}

/// Makes [getQueue] answer with an empty queue.
void _stubEmptyQueue(
  Future<QueueItems> Function({
    int page,
    int pageSize,
    String sortKey,
    String sortDirection,
  })
  getQueue,
) {
  when(
    () => getQueue(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
      sortKey: any(named: 'sortKey'),
      sortDirection: any(named: 'sortDirection'),
    ),
  ).thenAnswer(
    (_) async => const QueueItems(
      page: 1,
      pageSize: 100,
      sortKey: 'timeleft',
      sortDirection: 'ascending',
      totalRecords: 0,
      records: [],
    ),
  );
}

/// A `grabbed` history event of [movieId] carrying [downloadId].
HistoryEvent _grabbed({required int movieId, required String downloadId}) {
  return HistoryEvent.fromJson({
    'id': movieId,
    'eventType': 'grabbed',
    'date': '2026-01-01T00:00:00Z',
    'sourceTitle': 'Release',
    'movieId': movieId,
    'downloadId': downloadId,
    'quality': {
      'quality': {'id': 1, 'name': '1080p'},
      'revision': {'version': 1, 'real': 0},
    },
  });
}
