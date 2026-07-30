import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final movie = Movie(
    guid: 7,
    tmdbId: 123,
    imdbId: 'tt1234567',
    title: 'Test Movie',
    sortTitle: 'Test Movie',
    year: 2024,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    added: DateTime(2024),
  );

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        queueMediaLookupProvider.overrideWithValue(
          const AsyncValue.data(QueueMediaLookup.empty),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('MovieListTile should preserve long press selection', (
    tester,
  ) async {
    // Given
    var longPressed = false;
    await tester.pumpWidget(
      wrap(MovieListTile(movie: movie, onLongPress: () => longPressed = true)),
    );

    // When
    await tester.longPress(find.text('Test Movie'));

    // Then
    expect(longPressed, isTrue);
  });

  testWidgets('MovieListTile should render title and year', (tester) async {
    await tester.pumpWidget(wrap(MovieListTile(movie: movie)));

    expect(find.text('Test Movie'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
  });
}
