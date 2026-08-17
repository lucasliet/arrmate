import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/activity_screen.dart';
import 'package:arrmate/presentation/screens/activity/qbittorrent_tab.dart';
import 'package:arrmate/presentation/screens/calendar/calendar_screen.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/screens/series/series_screen.dart';
import 'package:arrmate/presentation/tour/tour_mock_data.dart';
import 'package:arrmate/presentation/tour/tour_mockup_provider.dart';
import 'package:arrmate/presentation/tour/widgets/tour_mockup_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tour notifier that starts already running, reproducing the state a fresh
/// install is in while the onboarding walks through the app.
class _RunningTourNotifier extends TourActiveNotifier {
  @override
  bool build() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('should mock the movie library while the tour runs', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(tester, const MoviesScreen());

    // Then
    expect(find.byKey(tourMockupBannerKey), findsOneWidget);
    expect(find.text(TourMockData.movies().first.title), findsOneWidget);
    expect(find.text('No movies found'), findsNothing);
  });

  testWidgets('should restore the movie empty state when the tour ends', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);
    await _pumpWithRunningTour(tester, const MoviesScreen());

    // When
    await _endTour(tester);

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text(TourMockData.movies().first.title), findsNothing);
    expect(find.text('No movies found'), findsOneWidget);
  });

  testWidgets('should mock the series library while the tour runs', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(tester, const SeriesScreen());

    // Then
    expect(find.byKey(tourMockupBannerKey), findsOneWidget);
    expect(find.text(TourMockData.series().first.title), findsOneWidget);
    expect(find.text('No series found'), findsNothing);
  });

  testWidgets('should restore the series empty state when the tour ends', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);
    await _pumpWithRunningTour(tester, const SeriesScreen());

    // When
    await _endTour(tester);

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text('No series found'), findsOneWidget);
  });

  testWidgets('should mock upcoming releases while the tour runs', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(tester, const CalendarScreen());

    // Then
    expect(find.byKey(tourMockupBannerKey), findsOneWidget);
    expect(
      find.text(TourMockData.calendarEvents().first.title),
      findsOneWidget,
    );
    expect(find.text('No upcoming events'), findsNothing);
  });

  testWidgets('should restore the calendar empty state when the tour ends', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);
    await _pumpWithRunningTour(tester, const CalendarScreen());

    // When
    await _endTour(tester);

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text('No upcoming events'), findsOneWidget);
  });

  testWidgets('should mock the download queue and reveal the torrents tab', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(tester, const ActivityScreen());

    // Then
    expect(find.byKey(tourMockupBannerKey), findsOneWidget);
    expect(find.text('Torrents'), findsOneWidget);
    expect(
      find.text(TourMockData.queueItems().first.displayTitle),
      findsOneWidget,
    );
    expect(find.text('Queue is empty'), findsNothing);
  });

  testWidgets('should hide the mocked torrents tab when the tour ends', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);
    await _pumpWithRunningTour(tester, const ActivityScreen());

    // When
    await _endTour(tester);

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text('Torrents'), findsNothing);
    expect(find.text('Queue is empty'), findsOneWidget);
  });

  testWidgets('should mock torrents while the tour runs', (tester) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(tester, const QBittorrentTab());

    // Then
    expect(find.byKey(tourMockupBannerKey), findsOneWidget);
    expect(find.text(TourMockData.torrents().first.name), findsOneWidget);
    expect(find.text('No Torrents'), findsNothing);
  });

  testWidgets('should restore the torrents empty state when the tour ends', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);
    await _pumpWithRunningTour(tester, const QBittorrentTab());

    // When
    await _endTour(tester);

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text('No Torrents'), findsOneWidget);
  });

  testWidgets('should keep the real empty state for configured services', (
    tester,
  ) async {
    // Given
    await _resizeSurface(tester);

    // When
    await _pumpWithRunningTour(
      tester,
      const MoviesScreen(),
      overrides: [
        tourMockupProvider(InstanceType.radarr).overrideWithValue(false),
      ],
    );

    // Then
    expect(find.byKey(tourMockupBannerKey), findsNothing);
    expect(find.text('No movies found'), findsOneWidget);
  });
}

Future<void> _resizeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpWithRunningTour(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tourActiveProvider.overrideWith(_RunningTourNotifier.new),
        ...overrides,
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finishes the tour the same way the Skip button and the last step do.
Future<void> _endTour(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  container.read(tourActiveProvider.notifier).stop();
  await tester.pumpAndSettle();
}
