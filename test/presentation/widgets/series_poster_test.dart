import 'dart:io';

import 'package:arrmate/data/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_image_http.dart';

void main() {
  setUpAll(() {
    registerMockFallbacks();
  });

  final testSeries = Series(
    title: 'Test Series',
    sortTitle: 'test series',
    tvdbId: 12345,
    year: 2023,
    monitored: true,
    seasonFolder: true,
    status: SeriesStatus.continuing,
    added: DateTime.now(),
    qualityProfileId: 1,
    seriesType: SeriesType.standard,
    images: [
      MediaImage(
        coverType: 'poster',
        url: '/MediaCover/1/poster.jpg',
      ),
    ],
    seasons: [],
  );

  final testSeriesWithRemotePoster = Series(
    title: 'Test Series Remote',
    sortTitle: 'test series remote',
    tvdbId: 67890,
    year: 2024,
    monitored: true,
    seasonFolder: true,
    status: SeriesStatus.continuing,
    added: DateTime.now(),
    qualityProfileId: 1,
    seriesType: SeriesType.standard,
    images: [
      MediaImage(
        coverType: 'poster',
        url: '/MediaCover/2/poster.jpg',
        remoteUrl: 'https://artworks.thetvdb.com/banners/poster.jpg',
      ),
    ],
    seasons: [],
  );

  final testSeriesWithoutImages = Series(
    title: 'No Poster Series',
    sortTitle: 'no poster series',
    tvdbId: 99999,
    year: 2025,
    monitored: false,
    seasonFolder: true,
    status: SeriesStatus.ended,
    added: DateTime.now(),
    qualityProfileId: 1,
    seriesType: SeriesType.standard,
    images: [],
    seasons: [],
  );

  group('SeriesPoster Widget', () {
    testWidgets(
      'should display placeholder when instance is null and no remote poster',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentSonarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: SeriesPoster(series: testSeries),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            // Then
            expect(find.byIcon(Icons.tv), findsOneWidget);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets(
      'should display placeholder when series has no images',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentSonarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: SeriesPoster(series: testSeriesWithoutImages),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            // Then
            expect(find.byIcon(Icons.tv), findsOneWidget);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets(
      'should display image when series has remote poster (no auth needed)',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentSonarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: SeriesPoster(series: testSeriesWithRemotePoster),
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();

            // Then
            expect(find.byType(SeriesPoster), findsOneWidget);
            expect(find.byIcon(Icons.tv), findsNothing);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets(
      'should display image when instance is configured and local poster exists',
      (tester) async {
        // Given
        final testInstance = Instance(
          id: 'test-instance',
          type: InstanceType.sonarr,
          url: 'http://localhost:8989',
          apiKey: 'test-api-key',
        );

        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentSonarrInstanceProvider.overrideWithValue(testInstance),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: SeriesPoster(series: testSeriesWithRemotePoster),
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();

            // Then
            expect(find.byType(SeriesPoster), findsOneWidget);
            expect(find.byIcon(Icons.tv), findsNothing);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );
  });
}
