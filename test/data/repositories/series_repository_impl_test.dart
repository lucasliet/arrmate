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
  });
}
