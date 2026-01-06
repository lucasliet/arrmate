import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';

class MockSeriesRepository extends Mock implements SeriesRepository {}

class FakeSeries extends Fake implements Series {}

void main() {
  late MockSeriesRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeSeries());
  });

  setUp(() {
    mockRepository = MockSeriesRepository();
  });

  group('SeriesController', () {
    group('toggleSeasonMonitor', () {
      test('Deve inverter monitored da season e chamar updateSeries', () async {
        // Given
        final series = Series(
          guid: 100,
          title: 'Test Series',
          sortTitle: 'Test Series',
          tvdbId: 12345,
          status: SeriesStatus.continuing,
          seriesType: SeriesType.standard,
          year: 2024,
          added: DateTime(2024, 1, 1),
          monitored: true,
          seasons: [
            const Season(seasonNumber: 1, monitored: true),
            const Season(seasonNumber: 2, monitored: false),
          ],
        );

        when(
          () => mockRepository.updateSeries(
            any(),
            moveFiles: any(named: 'moveFiles'),
          ),
        ).thenAnswer((_) async => series);

        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(seriesControllerProvider(100));

        // When
        await controller.toggleSeasonMonitor(series, 1);

        // Then
        final captured = verify(
          () => mockRepository.updateSeries(captureAny(), moveFiles: false),
        ).captured;

        final updatedSeries = captured.first as Series;
        final season1 = updatedSeries.seasons.firstWhere(
          (s) => s.seasonNumber == 1,
        );
        expect(season1.monitored, isFalse);
      });

      test(
        'Deve inverter monitored de season não monitorada para true',
        () async {
          // Given
          final series = Series(
            guid: 100,
            title: 'Test Series',
            sortTitle: 'Test Series',
            tvdbId: 12345,
            status: SeriesStatus.continuing,
            seriesType: SeriesType.standard,
            year: 2024,
            added: DateTime(2024, 1, 1),
            monitored: true,
            seasons: [
              const Season(seasonNumber: 1, monitored: true),
              const Season(seasonNumber: 2, monitored: false),
            ],
          );

          when(
            () => mockRepository.updateSeries(
              any(),
              moveFiles: any(named: 'moveFiles'),
            ),
          ).thenAnswer((_) async => series);

          final container = ProviderContainer(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(mockRepository),
            ],
          );
          addTearDown(container.dispose);

          final controller = container.read(seriesControllerProvider(100));

          // When
          await controller.toggleSeasonMonitor(series, 2);

          // Then
          final captured = verify(
            () => mockRepository.updateSeries(captureAny(), moveFiles: false),
          ).captured;

          final updatedSeries = captured.first as Series;
          final season2 = updatedSeries.seasons.firstWhere(
            (s) => s.seasonNumber == 2,
          );
          expect(season2.monitored, isTrue);
        },
      );

      test(
        'Não deve modificar outras seasons ao alterar uma específica',
        () async {
          // Given
          final series = Series(
            guid: 100,
            title: 'Test Series',
            sortTitle: 'Test Series',
            tvdbId: 12345,
            status: SeriesStatus.continuing,
            seriesType: SeriesType.standard,
            year: 2024,
            added: DateTime(2024, 1, 1),
            monitored: true,
            seasons: [
              const Season(seasonNumber: 1, monitored: true),
              const Season(seasonNumber: 2, monitored: false),
              const Season(seasonNumber: 3, monitored: true),
            ],
          );

          when(
            () => mockRepository.updateSeries(
              any(),
              moveFiles: any(named: 'moveFiles'),
            ),
          ).thenAnswer((_) async => series);

          final container = ProviderContainer(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(mockRepository),
            ],
          );
          addTearDown(container.dispose);

          final controller = container.read(seriesControllerProvider(100));

          // When
          await controller.toggleSeasonMonitor(series, 2);

          // Then
          final captured = verify(
            () => mockRepository.updateSeries(captureAny(), moveFiles: false),
          ).captured;

          final updatedSeries = captured.first as Series;
          final season1 = updatedSeries.seasons.firstWhere(
            (s) => s.seasonNumber == 1,
          );
          final season3 = updatedSeries.seasons.firstWhere(
            (s) => s.seasonNumber == 3,
          );

          expect(season1.monitored, isTrue);
          expect(season3.monitored, isTrue);
        },
      );
    });

    group('monitorAllSeasons', () {
      test(
        'Deve marcar todas as seasons como monitoradas quando true',
        () async {
          // Given
          final series = Series(
            guid: 100,
            title: 'Test Series',
            sortTitle: 'Test Series',
            tvdbId: 12345,
            status: SeriesStatus.continuing,
            seriesType: SeriesType.standard,
            year: 2024,
            added: DateTime(2024, 1, 1),
            monitored: true,
            seasons: [
              const Season(seasonNumber: 1, monitored: false),
              const Season(seasonNumber: 2, monitored: false),
              const Season(seasonNumber: 3, monitored: true),
            ],
          );

          when(
            () => mockRepository.updateSeries(
              any(),
              moveFiles: any(named: 'moveFiles'),
            ),
          ).thenAnswer((_) async => series);

          final container = ProviderContainer(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(mockRepository),
            ],
          );
          addTearDown(container.dispose);

          final controller = container.read(seriesControllerProvider(100));

          // When
          await controller.monitorAllSeasons(series, true);

          // Then
          final captured = verify(
            () => mockRepository.updateSeries(captureAny(), moveFiles: false),
          ).captured;

          final updatedSeries = captured.first as Series;
          expect(updatedSeries.seasons.every((s) => s.monitored), isTrue);
        },
      );

      test('Deve desmarcar todas as seasons quando false', () async {
        // Given
        final series = Series(
          guid: 100,
          title: 'Test Series',
          sortTitle: 'Test Series',
          tvdbId: 12345,
          status: SeriesStatus.continuing,
          seriesType: SeriesType.standard,
          year: 2024,
          added: DateTime(2024, 1, 1),
          monitored: true,
          seasons: [
            const Season(seasonNumber: 1, monitored: true),
            const Season(seasonNumber: 2, monitored: true),
            const Season(seasonNumber: 3, monitored: false),
          ],
        );

        when(
          () => mockRepository.updateSeries(
            any(),
            moveFiles: any(named: 'moveFiles'),
          ),
        ).thenAnswer((_) async => series);

        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(seriesControllerProvider(100));

        // When
        await controller.monitorAllSeasons(series, false);

        // Then
        final captured = verify(
          () => mockRepository.updateSeries(captureAny(), moveFiles: false),
        ).captured;

        final updatedSeries = captured.first as Series;
        expect(updatedSeries.seasons.every((s) => !s.monitored), isTrue);
      });
    });
  });
}
