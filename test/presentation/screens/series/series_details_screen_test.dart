import 'package:arrmate/core/services/purge_service.dart';
import 'package:arrmate/domain/models/models.dart';

import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_metadata_provider.dart';
import 'package:arrmate/presentation/shared/providers/formatted_options_provider.dart';
import 'package:arrmate/presentation/screens/series/series_details_screen.dart';
import 'package:arrmate/presentation/widgets/media/poster_viewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/localized_app.dart';

class MockPurgeService extends Mock implements PurgeService {}

/// A series list that counts how many times it was built.
class _CountingSeries extends SeriesNotifier {
  static int builds = 0;

  @override
  Future<List<Series>> build() async {
    builds++;
    return [];
  }
}

// Mock models
final mockInstance = Instance(
  id: '2',
  name: 'Test Sonarr',
  url: 'http://localhost:8989',
  apiKey: 'sonarr_apikey',
  type: InstanceType.sonarr,
);

Series createMockSeries({List<MediaImage> images = const [], String? imdbId}) {
  return Series(
    guid: 1,
    tvdbId: 100,
    imdbId: imdbId,
    title: 'Test Series',
    sortTitle: 'Test Series',
    year: 2023,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    monitored: true,
    qualityProfileId: 1,
    added: DateTime.now(),
    images: images,
    genres: ['Drama'],
    tags: [],
    seasons: [],
    statistics: const SeriesStatistics(
      sizeOnDisk: 0,
      seasonCount: 1,
      episodeCount: 10,
      episodeFileCount: 10,
      totalEpisodeCount: 10,
      percentOfEpisodes: 100,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SeriesDetailsScreen should prefer remoteUrl for background if available',
    (tester) async {
      const remoteUrl = 'http://remote.com/fanart.jpg';
      final series = createMockSeries(
        images: [
          MediaImage(
            coverType: 'fanart',
            url: '/local/fanart.jpg',
            remoteUrl: remoteUrl,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSonarrInstanceProvider.overrideWithValue(mockInstance),
            seriesDetailsProvider(1).overrideWith((ref) => series),
            seriesFilesProvider(1).overrideWith((ref) async => []),
            seriesExtraFilesProvider(1).overrideWith((ref) async => []),
            seriesHistoryProvider(1).overrideWith((ref) async => []),
            seriesQualityProfilesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: SeriesDetailsScreen(seriesId: 1),
          ),
        ),
      );

      // Wait for async operations
      await tester.pump();

      // Find CachedNetworkImage with correct URL
      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is CachedNetworkImage) {
          return widget.imageUrl == remoteUrl;
        }
        return false;
      });

      expect(imageFinder, findsOneWidget);
    },
  );

  testWidgets(
    'SeriesDetailsScreen should fall back to local URL with auth headers if remoteUrl is missing',
    (tester) async {
      const localUrl = '/local/fanart.jpg';
      final series = createMockSeries(
        images: [
          MediaImage(coverType: 'fanart', url: localUrl, remoteUrl: null),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSonarrInstanceProvider.overrideWithValue(mockInstance),
            seriesDetailsProvider(1).overrideWith((ref) => series),
            seriesFilesProvider(1).overrideWith((ref) async => []),
            seriesExtraFilesProvider(1).overrideWith((ref) async => []),
            seriesHistoryProvider(1).overrideWith((ref) async => []),
            seriesQualityProfilesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: SeriesDetailsScreen(seriesId: 1),
          ),
        ),
      );

      await tester.pump();

      final expectedUrl = 'http://localhost:8989/local/fanart.jpg';

      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is CachedNetworkImage) {
          return widget.imageUrl == expectedUrl &&
              widget.httpHeaders?['X-Api-Key'] == 'sonarr_apikey';
        }
        return false;
      });

      expect(imageFinder, findsOneWidget);
    },
  );

  testWidgets(
    'SeriesDetailsScreen should show fallback container if no images',
    (tester) async {
      final series = createMockSeries(images: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSonarrInstanceProvider.overrideWithValue(mockInstance),
            seriesDetailsProvider(1).overrideWith((ref) => series),
            seriesFilesProvider(1).overrideWith((ref) async => []),
            seriesExtraFilesProvider(1).overrideWith((ref) async => []),
            seriesHistoryProvider(1).overrideWith((ref) async => []),
            seriesQualityProfilesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            home: SeriesDetailsScreen(seriesId: 1),
          ),
        ),
      );

      await tester.pump();

      // The background stack is in the SliverAppBar.
      final backgroundStackFinder = find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.byType(Stack),
      );

      final cachedImageInBackground = find.descendant(
        of: backgroundStackFinder,
        matching: find.byType(CachedNetworkImage),
      );

      expect(cachedImageInBackground, findsNothing);
    },
  );

  testWidgets('SeriesDetailsScreen should show external actions', (
    tester,
  ) async {
    // Given
    final series = createMockSeries(imdbId: 'tt11280740');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(mockInstance),
          seriesDetailsProvider(1).overrideWith((ref) => series),
          seriesFilesProvider(1).overrideWith((ref) async => []),
          seriesExtraFilesProvider(1).overrideWith((ref) async => []),
          seriesHistoryProvider(1).overrideWith((ref) async => []),
          seriesQualityProfilesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: SeriesDetailsScreen(seriesId: 1),
        ),
      ),
    );

    // When
    await tester.pump();

    // Then
    expect(find.text('IMDb'), findsOneWidget);
    expect(find.text('Trakt'), findsOneWidget);
    expect(find.text('TVDB'), findsOneWidget);
  });

  testWidgets('SeriesDetailsScreen should open the poster viewer', (
    tester,
  ) async {
    // Given
    final series = createMockSeries();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(mockInstance),
          seriesDetailsProvider(1).overrideWith((ref) => series),
          seriesFilesProvider(1).overrideWith((ref) async => []),
          seriesExtraFilesProvider(1).overrideWith((ref) async => []),
          seriesHistoryProvider(1).overrideWith((ref) async => []),
          seriesQualityProfilesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: SeriesDetailsScreen(seriesId: 1),
        ),
      ),
    );
    await tester.pump();

    // When
    await tester.tap(find.byKey(const Key('viewSeriesPoster')));
    await tester.pumpAndSettle();

    // Then
    expect(find.byType(PosterViewer), findsOneWidget);
  });

  testWidgets('SeriesDetailsScreen should reload the series list when a purge '
      'fails after the catalog entry was deleted', (tester) async {
    // Given a purge that fails halfway, once the series is out of Sonarr
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(SeedingAction.deleteAll);
    _CountingSeries.builds = 0;
    final purgeService = MockPurgeService();
    when(
      () => purgeService.previewSeries(
        any(),
        minimumSeedingSeconds: any(named: 'minimumSeedingSeconds'),
      ),
    ).thenAnswer(
      (_) async => const PurgePreview(
        torrentsToDelete: [],
        crossSeedCandidates: [],
        belowThreshold: [],
        qbittorrentSkipped: true,
      ),
    );
    when(
      () => purgeService.purgeSeriesWithAction(
        any(),
        action: any(named: 'action'),
        minimumSeedingSeconds: any(named: 'minimumSeedingSeconds'),
        approvedCrossSeedHashes: any(named: 'approvedCrossSeedHashes'),
      ),
    ).thenThrow(StateError('qBittorrent down'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(mockInstance),
          seriesDetailsProvider(1).overrideWith((ref) => createMockSeries()),
          seriesFilesProvider(1).overrideWith((ref) async => []),
          seriesExtraFilesProvider(1).overrideWith((ref) async => []),
          seriesHistoryProvider(1).overrideWith((ref) async => []),
          seriesQualityProfilesProvider.overrideWith((ref) async => []),
          seriesProvider.overrideWith(_CountingSeries.new),
          purgeServiceProvider.overrideWithValue(purgeService),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(seriesProvider);
              return SeriesDetailsScreen(seriesId: 1);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_CountingSeries.builds, 1);

    // When the user purges the series
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purge'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Purge'));
    await tester.pumpAndSettle();

    // Then the error is shown and the list is read again
    expect(find.textContaining('Failed to purge'), findsOneWidget);
    expect(_CountingSeries.builds, 2);
  });
}
