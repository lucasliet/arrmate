import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/activity_screen.dart';
import 'package:arrmate/presentation/screens/calendar/calendar_screen.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/screens/movies/movie_details_screen.dart';
import 'package:arrmate/presentation/screens/movies/providers/movie_details_provider.dart';
import 'package:arrmate/presentation/screens/movies/providers/movies_provider.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_card.dart';
import 'package:arrmate/presentation/screens/series/series_screen.dart';
import 'package:arrmate/presentation/screens/series/series_details_screen.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_card.dart';
import 'package:arrmate/presentation/screens/settings/settings_screen.dart';
import 'package:arrmate/presentation/theme/app_theme.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final movies in [true, false]) {
    testWidgets(
      '${movies ? 'movie' : 'series'} details adapt heroes to local width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1700, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final width = ValueNotifier<double>(1199);
        addTearDown(width.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentRadarrInstanceProvider.overrideWithValue(null),
              currentSonarrInstanceProvider.overrideWithValue(null),
              movieDetailsProvider(
                1,
              ).overrideWith((ref) => TourMockData.movies().first),
              seriesDetailsProvider(
                1,
              ).overrideWith((ref) => TourMockData.series().first),
            ],
            child: MaterialApp(
              home: Align(
                alignment: Alignment.topLeft,
                child: ValueListenableBuilder<double>(
                  valueListenable: width,
                  builder: (context, value, child) =>
                      SizedBox(width: value, child: child),
                  child: movies
                      ? const MovieDetailsScreen(movieId: 1)
                      : const SeriesDetailsScreen(seriesId: 1),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<SliverAppBar>(find.byType(SliverAppBar)).expandedHeight,
          300,
        );
        width.value = 1200;
        await tester.pumpAndSettle();
        expect(
          tester.widget<SliverAppBar>(find.byType(SliverAppBar)).expandedHeight,
          360,
        );
        width.value = 320;
        await tester.pumpAndSettle();
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${movies ? 'movie' : 'series'} library retains search, selection, and scroll on resize',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1700, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final width = ValueNotifier<double>(1199);
        addTearDown(width.dispose);
        final sampleMovie = TourMockData.movies().first;
        final sampleSeries = TourMockData.series().first;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentRadarrInstanceProvider.overrideWithValue(null),
              currentSonarrInstanceProvider.overrideWithValue(null),
              filteredMoviesProvider.overrideWithValue(
                AsyncData(
                  List.generate(
                    100,
                    (index) => sampleMovie.copyWith(guid: index + 1),
                  ),
                ),
              ),
              filteredSeriesProvider.overrideWithValue(
                AsyncData(
                  List.generate(
                    100,
                    (index) => sampleSeries.copyWith(guid: index + 1),
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(AppColorScheme.blue),
              home: Align(
                alignment: Alignment.topLeft,
                child: ValueListenableBuilder<double>(
                  valueListenable: width,
                  builder: (context, value, child) =>
                      SizedBox(width: value, child: child),
                  child: movies ? const MoviesScreen() : const SeriesScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final addLabel = movies ? 'Add movie' : 'Add series';
        expect(find.text(addLabel), findsNothing);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        width.value = 1200;
        await tester.pumpAndSettle();
        expect(find.text(addLabel), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Keep my search');
        width.value = 599;
        await tester.pumpAndSettle();
        expect(find.text('Keep my search'), findsOneWidget);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TextField)),
        );
        expect(
          movies
              ? container.read(movieSearchProvider)
              : container.read(seriesSearchProvider),
          'Keep my search',
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        final firstCard = movies
            ? find.byType(MovieCard).first
            : find.byType(SeriesCard).first;
        await tester.longPress(firstCard);
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsWidgets);
        width.value = 1200;
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsWidgets);
        expect(find.byType(FloatingActionButton), findsNothing);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
        await tester.pumpAndSettle();
        final scrollable = find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        );
        final original = tester.state<ScrollableState>(scrollable);
        final offset = original.position.pixels;
        expect(offset, greaterThan(0));
        width.value = 700;
        await tester.pumpAndSettle();
        expect(tester.state(scrollable), same(original));
        expect(original.position.pixels, offset);
        expect(find.text('1 selected'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('calendar and settings use their constrained content width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final width = ValueNotifier<double>(899);
    final page = ValueNotifier<Widget>(const CalendarScreen());
    addTearDown(width.dispose);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredCalendarProvider.overrideWithValue(
            AsyncData(TourMockData.calendarEvents()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorScheme.blue),
          home: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder<double>(
              valueListenable: width,
              builder: (context, value, child) =>
                  SizedBox(width: value, child: child),
              child: ValueListenableBuilder<Widget>(
                valueListenable: page,
                builder: (context, value, child) => value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, isNull);
    final dayPanels = find.byWidgetPredicate(
      (widget) => widget is Card && widget.margin == EdgeInsets.zero,
    );
    expect(dayPanels, findsNothing);
    width.value = 900;
    await tester.pumpAndSettle();
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 88);
    expect(dayPanels, findsWidgets);

    page.value = const SettingsScreen();
    width.value = 1200;
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(5));
    expect(
      tester.getTopLeft(find.text('Instances')).dy,
      tester.getTopLeft(find.text('Appearance')).dy,
    );
    await tester.tap(find.text('Theme Mode'));
    await tester.pumpAndSettle();
    final dialogSurface = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getSize(dialogSurface).width, lessThanOrEqualTo(560));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    final original = tester.state<ScrollableState>(scrollable);
    width.value = 700;
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    expect(tester.state(scrollable), same(original));
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity retains the selected tab across content breakpoints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(899, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ActivityScreen())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    final original = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(original.index, 1);
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    await tester.pumpAndSettle();
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))),
      same(original),
    );
    expect(original.index, 1);
    expect(tester.getSize(find.byType(TabBarView)).width, 1100);
    expect(tester.takeException(), isNull);
  });
}
