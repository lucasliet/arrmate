
import 'package:arrmate/domain/models/models.dart';

import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/screens/series/series_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock models
final mockInstance = Instance(
  id: '2',
  name: 'Test Sonarr',
  url: 'http://localhost:8989',
  apiKey: 'sonarr_apikey',
  type: InstanceType.sonarr,
);

Series createMockSeries({
  List<MediaImage> images = const [],
}) {
  return Series(
    guid: 1,
    tvdbId: 100,
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
        ],
        child: MaterialApp(
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
  });

  testWidgets(
      'SeriesDetailsScreen should fall back to local URL with auth headers if remoteUrl is missing',
      (tester) async {
    const localUrl = '/local/fanart.jpg';
    final series = createMockSeries(
      images: [
        MediaImage(
          coverType: 'fanart',
          url: localUrl,
          remoteUrl: null,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(mockInstance),
          seriesDetailsProvider(1).overrideWith((ref) => series),
        ],
        child: MaterialApp(
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
  });

  testWidgets('SeriesDetailsScreen should show fallback container if no images',
      (tester) async {
    final series = createMockSeries(images: []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSonarrInstanceProvider.overrideWithValue(mockInstance),
          seriesDetailsProvider(1).overrideWith((ref) => series),
        ],
        child: MaterialApp(
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
  });
}
