import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final series = Series(
    guid: 9,
    title: 'Test Series',
    sortTitle: 'Test Series',
    tvdbId: 371980,
    imdbId: 'tt11280740',
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2024,
    added: DateTime(2024),
  );

  testWidgets('SeriesCard should preserve long press selection', (
    tester,
  ) async {
    // Given
    var longPressed = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: SeriesCard(
                series: series,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      ),
    );

    // When
    await tester.longPress(find.text('Test Series'));

    // Then
    expect(longPressed, isTrue);
  });

  testWidgets('SeriesCard should dispatch automatic search', (tester) async {
    // Given
    var searchCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: SeriesCard(
                series: series,
                onAutomaticSearch: () async => searchCount++,
                onOpenExternal: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    // When
    await tester.tap(find.byKey(const Key('seriesQuickActions-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic Search'));
    await tester.pumpAndSettle();

    // Then
    expect(searchCount, 1);
  });
}
