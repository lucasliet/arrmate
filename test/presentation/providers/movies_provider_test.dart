import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

void main() {
  late MockMovieRepository mockRepository;

  setUp(() {
    mockRepository = MockMovieRepository();
  });

  test('MoviesNotifier should emit empty list initially', () async {
    final container = ProviderContainer(
      overrides: [movieRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    when(() => mockRepository.getMovies()).thenAnswer((_) async => []);

    // Listen to the provider
    final listener = container.listen(moviesProvider, (_, __) {});

    // wait for async build
    await container.read(moviesProvider.future);

    expect(container.read(moviesProvider).value, isEmpty);
  });

  test(
    'MoviesNotifier should emit movies when repository returns data',
    () async {
      final List<Movie> movies = [
        Movie(
          tmdbId: 12345,
          title: 'Test Movie',
          sortTitle: 'test movie',
          runtime: 120,
          year: 2023,
          monitored: true,
          hasFile: true,
          isAvailable: true,
          minimumAvailability: MovieStatus.released,
          status: MovieStatus.released,
          added: DateTime.now(),
          qualityProfileId: 1,
          images: [],
        ),
      ];

      final container = ProviderContainer(
        overrides: [movieRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      when(() => mockRepository.getMovies()).thenAnswer((_) async => movies);

      await container.read(moviesProvider.future);

      expect(container.read(moviesProvider).value, hasLength(1));
      expect(container.read(moviesProvider).value!.first.title, 'Test Movie');
    },
  );
}
