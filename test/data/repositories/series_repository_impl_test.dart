import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/data/repositories/series_repository_impl.dart';
import 'package:arrmate/domain/models/models.dart';

class MockSonarrApi extends Mock implements SonarrApi {}

class FakeSeries extends Fake implements Series {}

void main() {
  late MockSonarrApi mockApi;
  late SeriesRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeSeries());
  });

  setUp(() {
    mockApi = MockSonarrApi();
    repository = SeriesRepositoryImpl(mockApi);
  });

  group('SeriesRepositoryImpl - Edição e Configuração', () {
    final tSeries = Series(
      title: 'Test Series',
      sortTitle: 'Test Series',
      tvdbId: 12345,
      status: SeriesStatus.continuing,
      seriesType: SeriesType.standard,
      year: 2024,
      added: DateTime(2024, 1, 1),
    );

    test(
      'updateSeries deve chamar API com moveFiles=false por padrão',
      () async {
        // Given
        when(
          () => mockApi.updateSeries(any(), moveFiles: any(named: 'moveFiles')),
        ).thenAnswer((_) async => tSeries);

        // When
        await repository.updateSeries(tSeries);

        // Then
        verify(() => mockApi.updateSeries(tSeries, moveFiles: false)).called(1);
      },
    );

    test(
      'updateSeries deve repassar moveFiles=true para API quando solicitado',
      () async {
        // Given
        when(
          () => mockApi.updateSeries(any(), moveFiles: any(named: 'moveFiles')),
        ).thenAnswer((_) async => tSeries);

        // When
        await repository.updateSeries(tSeries, moveFiles: true);

        // Then
        verify(() => mockApi.updateSeries(tSeries, moveFiles: true)).called(1);
      },
    );

    test('getRootFolders deve retornar lista da API', () async {
      // Given
      final folders = [
        const RootFolder(id: 1, path: '/tv', freeSpace: 1000),
        const RootFolder(id: 2, path: '/tv2', freeSpace: 2000),
      ];
      when(() => mockApi.getRootFolders()).thenAnswer((_) async => folders);

      // When
      final result = await repository.getRootFolders();

      // Then
      expect(result, folders);
      verify(() => mockApi.getRootFolders()).called(1);
    });
  });

  group('SeriesRepositoryImpl - Files & History', () {
    test('getSeriesFiles deve chamar API com seriesId', () async {
      // Given
      final expectedFiles = <MediaFile>[];
      when(
        () => mockApi.getSeriesFiles(any()),
      ).thenAnswer((_) async => expectedFiles);

      // When
      final result = await repository.getSeriesFiles(100);

      // Then
      expect(result, expectedFiles);
      verify(() => mockApi.getSeriesFiles(100)).called(1);
    });

    test('getSeriesExtraFiles deve chamar API com seriesId', () async {
      // Given
      final expectedFiles = <SeriesExtraFile>[];
      when(
        () => mockApi.getSeriesExtraFiles(any()),
      ).thenAnswer((_) async => expectedFiles);

      // When
      final result = await repository.getSeriesExtraFiles(100);

      // Then
      expect(result, expectedFiles);
      verify(() => mockApi.getSeriesExtraFiles(100)).called(1);
    });

    test('getSeriesHistory deve chamar API com seriesId', () async {
      // Given
      final expectedHistory = <HistoryEvent>[];
      when(
        () => mockApi.getSeriesHistory(any()),
      ).thenAnswer((_) async => expectedHistory);

      // When
      final result = await repository.getSeriesHistory(100);

      // Then
      expect(result, expectedHistory);
      verify(() => mockApi.getSeriesHistory(100)).called(1);
    });

    test('deleteSeriesFile deve chamar API com fileId', () async {
      // Given
      when(() => mockApi.deleteSeriesFile(any())).thenAnswer((_) async {});

      // When
      await repository.deleteSeriesFile(50);

      // Then
      verify(() => mockApi.deleteSeriesFile(50)).called(1);
    });

    test(
      'deleteSeriesFiles sem seasonNumber deve excluir todos os arquivos da série',
      () async {
        // Given
        final files = [
          MediaFile(id: 10, size: 1, dateAdded: DateTime(2024)),
          MediaFile(id: 20, size: 1, dateAdded: DateTime(2024)),
          MediaFile(id: 30, size: 1, dateAdded: DateTime(2024)),
        ];
        when(
          () => mockApi.getSeriesFiles(any()),
        ).thenAnswer((_) async => files);
        when(() => mockApi.deleteSeriesFile(any())).thenAnswer((_) async {});

        // When
        final count = await repository.deleteSeriesFiles(7);

        // Then
        expect(count, 3);
        verify(() => mockApi.getSeriesFiles(7)).called(1);
        verifyNever(() => mockApi.getEpisodes(any()));
        verify(() => mockApi.deleteSeriesFile(10)).called(1);
        verify(() => mockApi.deleteSeriesFile(20)).called(1);
        verify(() => mockApi.deleteSeriesFile(30)).called(1);
      },
    );

    test(
      'deleteSeriesFiles com seasonNumber filtra por temporada, hasFile e deduplica fileIds',
      () async {
        // Given
        final episodes = [
          // Season 1 — match (fileId 100)
          const Episode(
            id: 1,
            seriesId: 7,
            seasonNumber: 1,
            episodeNumber: 1,
            hasFile: true,
            episodeFileId: 100,
          ),
          // Season 1 — match, shares fileId 100 with above (multi-episode file)
          const Episode(
            id: 2,
            seriesId: 7,
            seasonNumber: 1,
            episodeNumber: 2,
            hasFile: true,
            episodeFileId: 100,
          ),
          // Season 1 — match (fileId 101)
          const Episode(
            id: 3,
            seriesId: 7,
            seasonNumber: 1,
            episodeNumber: 3,
            hasFile: true,
            episodeFileId: 101,
          ),
          // Season 1 — no file
          const Episode(
            id: 4,
            seriesId: 7,
            seasonNumber: 1,
            episodeNumber: 4,
            hasFile: false,
            episodeFileId: null,
          ),
          // Season 1 — hasFile but invalid id
          const Episode(
            id: 5,
            seriesId: 7,
            seasonNumber: 1,
            episodeNumber: 5,
            hasFile: true,
            episodeFileId: 0,
          ),
          // Season 2 — must not be touched
          const Episode(
            id: 6,
            seriesId: 7,
            seasonNumber: 2,
            episodeNumber: 1,
            hasFile: true,
            episodeFileId: 200,
          ),
        ];
        when(
          () => mockApi.getEpisodes(any()),
        ).thenAnswer((_) async => episodes);
        when(() => mockApi.deleteSeriesFile(any())).thenAnswer((_) async {});

        // When
        final count = await repository.deleteSeriesFiles(7, seasonNumber: 1);

        // Then
        expect(count, 2);
        verify(() => mockApi.getEpisodes(7)).called(1);
        verifyNever(() => mockApi.getSeriesFiles(any()));
        verify(() => mockApi.deleteSeriesFile(100)).called(1);
        verify(() => mockApi.deleteSeriesFile(101)).called(1);
        verifyNever(() => mockApi.deleteSeriesFile(200));
        verifyNever(() => mockApi.deleteSeriesFile(0));
      },
    );
  });

  group('SeriesRepositoryImpl - Manual Import', () {
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

  group('SeriesRepositoryImpl - Search', () {
    test('searchSeries deve chamar API com seriesId', () async {
      // Given
      when(() => mockApi.seriesSearch(any())).thenAnswer((_) async {});

      // When
      await repository.searchSeries(42);

      // Then
      verify(() => mockApi.seriesSearch(42)).called(1);
    });

    test('searchEpisode deve chamar API com episodeId', () async {
      // Given
      when(() => mockApi.episodeSearch(any())).thenAnswer((_) async {});

      // When
      await repository.searchEpisode(123);

      // Then
      verify(() => mockApi.episodeSearch(123)).called(1);
    });

    test('searchSeason deve chamar API com seriesId e seasonNumber', () async {
      // Given
      when(() => mockApi.seasonSearch(any(), any())).thenAnswer((_) async {});

      // When
      await repository.searchSeason(42, 3);

      // Then
      verify(() => mockApi.seasonSearch(42, 3)).called(1);
    });
  });
}
