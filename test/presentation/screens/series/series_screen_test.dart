import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/series_screen.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_card.dart';
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
    final sample = TourMockData.series().first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRadarrInstanceProvider.overrideWithValue(null),
          currentSonarrInstanceProvider.overrideWithValue(null),
          filteredSeriesProvider.overrideWithValue(
            AsyncData([sample.copyWith(guid: 1), sample.copyWith(guid: 2)]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: SeriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(SeriesCard).first);
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
}
