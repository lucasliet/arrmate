import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/repositories/movie_repository_impl.dart';
import 'package:arrmate/domain/models/models.dart';

class MockRadarrApi extends Mock implements RadarrApi {}

class FakeMovie extends Fake implements Movie {}

void main() {
  late MockRadarrApi mockApi;
  late MovieRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeMovie());
  });

  setUp(() {
    mockApi = MockRadarrApi();
    repository = MovieRepositoryImpl(mockApi);
  });

  group('MovieRepositoryImpl - Edição', () {
    final tMovie = Movie(
      guid: 1,
      tmdbId: 100,
      title: 'Test Movie',
      sortTitle: 'Test Movie',
      status: MovieStatus.released,
      year: 2024,
      added: DateTime(2024, 1, 1),
      monitored: true,
      qualityProfileId: 1,
      minimumAvailability: MovieStatus.released,
      runtime: 120,
      isAvailable: true,
    );

    test('updateMovie deve chamar API com moveFiles=false por padrão', () async {
      // Given
      when(() => mockApi.updateMovie(any(), moveFiles: any(named: 'moveFiles')))
          .thenAnswer((_) async => tMovie);

      // When
      await repository.updateMovie(tMovie);

      // Then
      verify(() => mockApi.updateMovie(tMovie, moveFiles: false)).called(1);
    });

    test('updateMovie deve repassar moveFiles=true para API quando solicitado', () async {
      // Given
      when(() => mockApi.updateMovie(any(), moveFiles: any(named: 'moveFiles')))
          .thenAnswer((_) async => tMovie);

      // When
      await repository.updateMovie(tMovie, moveFiles: true);

      // Then
      verify(() => mockApi.updateMovie(tMovie, moveFiles: true)).called(1);
    });
  });
}
