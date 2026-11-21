import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_card.dart';
import 'package:arrmate/presentation/shared/widgets/batch_action_bar.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/localized_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('should keep the selection when a batch purge is cancelled', (
    tester,
  ) async {
    // Given
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sample = TourMockData.movies().first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRadarrInstanceProvider.overrideWithValue(null),
          currentSonarrInstanceProvider.overrideWithValue(null),
          filteredMoviesProvider.overrideWithValue(
            AsyncData([sample.copyWith(guid: 1), sample.copyWith(guid: 2)]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: MoviesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(BatchActionBar), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purge'));
    await tester.pumpAndSettle();

    // When
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(BatchActionBar), findsOneWidget);
    expect(
      tester.widget<BatchActionBar>(find.byType(BatchActionBar)).selectedCount,
      1,
    );
  });

  testWidgets('should fit the app bar actions on a 360 px wide screen', (
    tester,
  ) async {
    // Given
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sample = TourMockData.movies().first;

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRadarrInstanceProvider.overrideWithValue(null),
          currentSonarrInstanceProvider.overrideWithValue(null),
          filteredMoviesProvider.overrideWithValue(
            AsyncData([sample.copyWith(guid: 1)]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: MoviesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Then
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
