import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/repositories/movie_repository_impl.dart';
import 'package:arrmate/domain/models/models.dart';

class MockRadarrApi extends Mock implements RadarrApi {}

void main() {
  late MockRadarrApi mockApi;
  late MovieRepositoryImpl repository;

  setUp(() {
    mockApi = MockRadarrApi();
    repository = MovieRepositoryImpl(mockApi);
  });

  group('MovieRepository - Advanced', () {
    test('getLogs deve retornar LogPage da API', () async {
      final expectedPage = LogPage(
        page: 1,
        pageSize: 50,
        totalRecords: 1,
        records: [
          LogEntry(
            time: DateTime.now(),
            level: 'info',
            logger: 'Test',
            message: 'Message',
          ),
        ],
      );

      when(
        () => mockApi.getLogs(page: 1, pageSize: 50),
      ).thenAnswer((_) async => expectedPage);

      final result = await repository.getLogs(page: 1, pageSize: 50);

      expect(result, expectedPage);
      verify(() => mockApi.getLogs(page: 1, pageSize: 50)).called(1);
    });

    test('getHealth deve retornar lista de HealthCheck da API', () async {
      final expectedHealth = [
        const HealthCheck(
          source: 'Test',
          type: 'error',
          message: 'Failure',
          wikiUrl: '',
        ),
      ];

      when(() => mockApi.getHealth()).thenAnswer((_) async => expectedHealth);

      final result = await repository.getHealth();

      expect(result, expectedHealth);
      verify(() => mockApi.getHealth()).called(1);
    });
  });
}
