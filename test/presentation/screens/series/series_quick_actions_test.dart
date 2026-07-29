import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/series_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should route quick search to the series origin instance', (
    tester,
  ) async {
    // Given
    SharedPreferences.setMockInitialValues({});
    final origin = Instance(
      id: 'sonarr-origin',
      name: 'Origin',
      url: 'https://sonarr.example.com',
      apiKey: 'api-key',
      type: InstanceType.sonarr,
    );
    final series = Series(
      guid: 9,
      instanceId: origin.id,
      title: 'Test Series',
      sortTitle: 'Test Series',
      tvdbId: 371980,
      status: SeriesStatus.continuing,
      seriesType: SeriesType.standard,
      year: 2024,
      added: DateTime(2024),
    );
    final repository = MockSeriesRepository();
    when(() => repository.searchSeries(series.id)).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredSeriesProvider.overrideWithValue(AsyncData([series])),
          currentSonarrInstanceProvider.overrideWithValue(origin),
          instancesByTypeProvider(
            InstanceType.sonarr,
          ).overrideWithValue([origin]),
          seriesRepositoryForInstanceProvider(
            origin,
          ).overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SeriesScreen()),
      ),
    );
    await tester.pump();

    // When
    await tester.tap(find.byKey(const Key('seriesQuickActions-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic Search'));
    await tester.pumpAndSettle();

    // Then
    verify(() => repository.searchSeries(series.id)).called(1);
    expect(
      find.text('Automatic search started for Test Series'),
      findsOneWidget,
    );
  });
}
