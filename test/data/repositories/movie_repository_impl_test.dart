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

    test(
      'updateMovie deve chamar API com moveFiles=false por padrão',
      () async {
        // Given
        when(
          () => mockApi.updateMovie(any(), moveFiles: any(named: 'moveFiles')),
        ).thenAnswer((_) async => tMovie);

        // When
        await repository.updateMovie(tMovie);

        // Then
        verify(() => mockApi.updateMovie(tMovie, moveFiles: false)).called(1);
      },
    );

    test(
      'updateMovie deve repassar moveFiles=true para API quando solicitado',
      () async {
        // Given
        when(
          () => mockApi.updateMovie(any(), moveFiles: any(named: 'moveFiles')),
        ).thenAnswer((_) async => tMovie);

        // When
        await repository.updateMovie(tMovie, moveFiles: true);

        // Then
        verify(() => mockApi.updateMovie(tMovie, moveFiles: true)).called(1);
      },
    );
  });

  group('MovieRepositoryImpl - Files & History', () {
    test('getMovieFiles deve chamar API com movieId', () async {
      // Given
      final expectedFiles = <MediaFile>[];
      when(
        () => mockApi.getMovieFiles(any()),
      ).thenAnswer((_) async => expectedFiles);

      // When
      final result = await repository.getMovieFiles(100);

      // Then
      expect(result, expectedFiles);
      verify(() => mockApi.getMovieFiles(100)).called(1);
    });

    test('getMovieExtraFiles deve chamar API com movieId', () async {
      // Given
      final expectedFiles = <MovieExtraFile>[];
      when(
        () => mockApi.getMovieExtraFiles(any()),
      ).thenAnswer((_) async => expectedFiles);

      // When
      final result = await repository.getMovieExtraFiles(100);

      // Then
      expect(result, expectedFiles);
      verify(() => mockApi.getMovieExtraFiles(100)).called(1);
    });

    test('getMovieHistory deve chamar API com movieId', () async {
      // Given
      final expectedHistory = <HistoryEvent>[];
      when(
        () => mockApi.getMovieHistory(any()),
      ).thenAnswer((_) async => expectedHistory);

      // When
      final result = await repository.getMovieHistory(100);

      // Then
      expect(result, expectedHistory);
      verify(() => mockApi.getMovieHistory(100)).called(1);
    });

    test('deleteMovieFile deve chamar API com fileId', () async {
      // Given
      when(() => mockApi.deleteMovieFile(any())).thenAnswer((_) async {});

      // When
      await repository.deleteMovieFile(50);

      // Then
      verify(() => mockApi.deleteMovieFile(50)).called(1);
    });

    test(
      'deleteMovieFiles deve buscar arquivos e deletar cada um, retornando a contagem',
      () async {
        // Given
        final files = [
          MediaFile(id: 10, size: 1000, dateAdded: DateTime(2024, 1, 1)),
          MediaFile(id: 20, size: 2000, dateAdded: DateTime(2024, 1, 2)),
          MediaFile(id: 30, size: 3000, dateAdded: DateTime(2024, 1, 3)),
        ];
        when(() => mockApi.getMovieFiles(any())).thenAnswer((_) async => files);
        when(() => mockApi.deleteMovieFile(any())).thenAnswer((_) async {});

        // When
        final count = await repository.deleteMovieFiles(7);

        // Then
        expect(count, 3);
        verify(() => mockApi.getMovieFiles(7)).called(1);
        verify(() => mockApi.deleteMovieFile(10)).called(1);
        verify(() => mockApi.deleteMovieFile(20)).called(1);
        verify(() => mockApi.deleteMovieFile(30)).called(1);
      },
    );

    test(
      'deleteMovieFiles deve deduplicar fileIds repetidos e retornar contagem unica',
      () async {
        // Given
        final files = [
          MediaFile(id: 10, size: 1000, dateAdded: DateTime(2024, 1, 1)),
          MediaFile(id: 10, size: 1000, dateAdded: DateTime(2024, 1, 1)),
          MediaFile(id: 20, size: 2000, dateAdded: DateTime(2024, 1, 2)),
        ];
        when(() => mockApi.getMovieFiles(any())).thenAnswer((_) async => files);
        when(() => mockApi.deleteMovieFile(any())).thenAnswer((_) async {});

        // When
        final count = await repository.deleteMovieFiles(7);

        // Then
        expect(count, 2);
        verify(() => mockApi.getMovieFiles(7)).called(1);
        verify(() => mockApi.deleteMovieFile(10)).called(1);
        verify(() => mockApi.deleteMovieFile(20)).called(1);
      },
    );

    test('deleteMovieFiles deve retornar 0 quando nao ha arquivos', () async {
      // Given
      when(() => mockApi.getMovieFiles(any())).thenAnswer((_) async => []);
      when(() => mockApi.deleteMovieFile(any())).thenAnswer((_) async {});

      // When
      final count = await repository.deleteMovieFiles(7);

      // Then
      expect(count, 0);
      verify(() => mockApi.getMovieFiles(7)).called(1);
      verifyNever(() => mockApi.deleteMovieFile(any()));
    });
  });

  group('MovieRepositoryImpl - Manual Import', () {
    test('getImportableFiles deve chamar API com downloadId', () async {
      // Given
      final expectedFiles = <ImportableFile>[];
      when(
        () => mockApi.getImportableFiles(any()),
      ).thenAnswer((_) async => expectedFiles);

      // When
      final result = await repository.getImportableFiles('download123');

      // Then
      expect(result, expectedFiles);
      verify(() => mockApi.getImportableFiles('download123')).called(1);
    });

    test('manualImport deve chamar API com lista de arquivos', () async {
      // Given
      final files = [
        ImportableFile(id: 1, size: 1000),
        ImportableFile(id: 2, size: 2000),
      ];
      when(() => mockApi.manualImport(any())).thenAnswer((_) async {});

      // When
      await repository.manualImport(files);

      // Then
      verify(() => mockApi.manualImport(files)).called(1);
    });
  });
}
