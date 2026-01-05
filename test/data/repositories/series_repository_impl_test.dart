import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/data/repositories/series_repository_impl.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/models/shared/root_folder.dart';

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

    test('updateSeries deve chamar API com moveFiles=false por padrão', () async {
      // Given
      when(() => mockApi.updateSeries(any(), moveFiles: any(named: 'moveFiles')))
          .thenAnswer((_) async => tSeries);

      // When
      await repository.updateSeries(tSeries);

      // Then
      verify(() => mockApi.updateSeries(tSeries, moveFiles: false)).called(1);
    });

    test('updateSeries deve repassar moveFiles=true para API quando solicitado', () async {
      // Given
      when(() => mockApi.updateSeries(any(), moveFiles: any(named: 'moveFiles')))
          .thenAnswer((_) async => tSeries);

      // When
      await repository.updateSeries(tSeries, moveFiles: true);

      // Then
      verify(() => mockApi.updateSeries(tSeries, moveFiles: true)).called(1);
    });

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
}
