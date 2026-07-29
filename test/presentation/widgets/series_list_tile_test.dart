import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_list_tile.dart';
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

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        queueMediaLookupProvider.overrideWithValue(
          const AsyncValue.data(QueueMediaLookup()),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('SeriesListTile should preserve long press selection', (
    tester,
  ) async {
    // Given
    var longPressed = false;
    await tester.pumpWidget(
      wrap(
        SeriesListTile(series: series, onLongPress: () => longPressed = true),
      ),
    );

    // When
    await tester.longPress(find.text('Test Series'));

    // Then
    expect(longPressed, isTrue);
  });

  testWidgets('SeriesListTile should dispatch a TVDB quick action', (
    tester,
  ) async {
    // Given
    Uri? openedUri;
    await tester.pumpWidget(
      wrap(
        SeriesListTile(
          series: series,
          onAutomaticSearch: () async {},
          onOpenExternal: (uri) async => openedUri = uri,
        ),
      ),
    );

    // When
    await tester.tap(find.byKey(const Key('seriesListQuickActions-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open in TVDB'));
    await tester.pumpAndSettle();

    // Then
    expect(openedUri?.host, 'www.thetvdb.com');
    expect(openedUri?.queryParameters['id'], '371980');
  });
}
