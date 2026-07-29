import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should route quick search to the movie origin instance', (
    tester,
  ) async {
    // Given
    SharedPreferences.setMockInitialValues({});
    final origin = Instance(
      id: 'radarr-origin',
      name: 'Origin',
      url: 'https://radarr.example.com',
      apiKey: 'api-key',
      type: InstanceType.radarr,
    );
    final movie = Movie(
      guid: 7,
      instanceId: origin.id,
      tmdbId: 123,
      title: 'Test Movie',
      sortTitle: 'Test Movie',
      year: 2024,
      runtime: 120,
      status: MovieStatus.released,
      isAvailable: true,
      minimumAvailability: MovieStatus.released,
      monitored: true,
      qualityProfileId: 1,
      added: DateTime(2024),
    );
    final repository = MockMovieRepository();
    when(
      () => repository.searchMovies(any(that: equals([movie.id]))),
    ).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredMoviesProvider.overrideWithValue(AsyncData([movie])),
          currentRadarrInstanceProvider.overrideWithValue(origin),
          instancesByTypeProvider(
            InstanceType.radarr,
          ).overrideWithValue([origin]),
          movieRepositoryForInstanceProvider(
            origin,
          ).overrideWithValue(repository),
        ],
        child: const MaterialApp(home: MoviesScreen()),
      ),
    );
    await tester.pump();

    // When
    await tester.tap(find.byKey(const Key('movieQuickActions-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic Search'));
    await tester.pumpAndSettle();

    // Then
    verify(
      () => repository.searchMovies(any(that: equals([movie.id]))),
    ).called(1);
    expect(
      find.text('Automatic search started for Test Movie'),
      findsOneWidget,
    );
  });
}
