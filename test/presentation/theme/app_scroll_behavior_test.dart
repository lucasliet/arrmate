import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_card.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/series_screen.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_card.dart';
import 'package:arrmate/presentation/theme/app_scroll_behavior.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final movies in [true, false]) {
    testWidgets(
      '${movies ? 'movie' : 'series'} library refreshes from a mouse drag with one search result',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var loads = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentRadarrInstanceProvider.overrideWithValue(null),
              currentSonarrInstanceProvider.overrideWithValue(null),
              if (movies)
                moviesProvider.overrideWith(() => _Movies(() => loads++))
              else
                seriesProvider.overrideWith(() => _Series(() => loads++)),
            ],
            child: MaterialApp(
              scrollBehavior: const AppScrollBehavior(),
              home: movies ? const MoviesScreen() : const SeriesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(loads, 1);
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        final query = movies ? 'Northern' : 'Blue';
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TextField)),
        );
        final results = movies
            ? container.read(filteredMoviesProvider).requireValue.length
            : container.read(filteredSeriesProvider).requireValue.length;
        expect(results, 1);
        final scrollable = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        expect(
          tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
          0,
        );

        final gesture = await tester.startGesture(
          const Offset(600, 400),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveBy(const Offset(0, 300));
        await tester.pump(const Duration(milliseconds: 200));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(loads, 2);
        expect(find.text(query), findsNothing);
        expect(
          movies
              ? container.read(movieSearchProvider)
              : container.read(seriesSearchProvider),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${movies ? 'movie' : 'series'} library selects from a stationary mouse hold',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentRadarrInstanceProvider.overrideWithValue(null),
              currentSonarrInstanceProvider.overrideWithValue(null),
              if (movies)
                moviesProvider.overrideWith(() => _Movies(() {}))
              else
                seriesProvider.overrideWith(() => _Series(() {})),
            ],
            child: MaterialApp(
              scrollBehavior: const AppScrollBehavior(),
              home: movies ? const MoviesScreen() : const SeriesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = movies
            ? find.byType(MovieCard).first
            : find.byType(SeriesCard).first;
        final gesture = await tester.startGesture(
          tester.getCenter(card),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 800));
        await gesture.up();
        await tester.pumpAndSettle();
        // The count is exposed by the selection chrome more than once.
        expect(find.text('1 selected'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Movies extends MoviesNotifier {
  _Movies(this.onLoad);
  final VoidCallback onLoad;

  @override
  List<Movie> build() {
    onLoad();
    return TourMockData.movies();
  }
}

class _Series extends SeriesNotifier {
  _Series(this.onLoad);
  final VoidCallback onLoad;

  @override
  List<Series> build() {
    onLoad();
    return TourMockData.series();
  }
}
