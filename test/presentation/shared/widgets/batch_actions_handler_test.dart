import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/shared/widgets/batch_actions_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

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
}
