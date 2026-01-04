import 'dart:io';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_image_http.dart';

void main() {
  setUpAll(() {
    registerMockFallbacks();
  });

  final testMovie = Movie(
    tmdbId: 12345,
    title: 'Test Movie',
    sortTitle: 'test movie',
    year: 2023,
    runtime: 120,
    monitored: true,
    hasFile: true,
    isAvailable: true,
    status: MovieStatus.released,
    minimumAvailability: MovieStatus.released,
    added: DateTime.now(),
    qualityProfileId: 1,
    images: [
      MediaImage(
        coverType: 'poster',
        url: '/MediaCover/1/poster.jpg',
      ),
    ],
  );

  final testMovieWithRemotePoster = Movie(
    tmdbId: 12345,
    title: 'Test Movie Remote',
    sortTitle: 'test movie remote',
    year: 2024,
    runtime: 90,
    monitored: true,
    hasFile: false,
    isAvailable: true,
    status: MovieStatus.released,
    minimumAvailability: MovieStatus.released,
    added: DateTime.now(),
    qualityProfileId: 1,
    images: [
      MediaImage(
        coverType: 'poster',
        url: '/MediaCover/2/poster.jpg',
        remoteUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
      ),
    ],
  );

  final testMovieWithoutImages = Movie(
    tmdbId: 99999,
    title: 'No Poster Movie',
    sortTitle: 'no poster movie',
    year: 2025,
    runtime: 60,
    monitored: false,
    hasFile: false,
    isAvailable: false,
    status: MovieStatus.announced,
    minimumAvailability: MovieStatus.announced,
    added: DateTime.now(),
    qualityProfileId: 1,
    images: [],
  );

  group('MoviePoster Widget', () {
    testWidgets(
      'should display placeholder when instance is null and no remote poster',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentRadarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: MoviePoster(movie: testMovie),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            // Then
            expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets(
      'should display placeholder when movie has no images',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentRadarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: MoviePoster(movie: testMovieWithoutImages),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            // Then
            expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );

    testWidgets(
      'should display image when movie has remote poster (no auth needed)',
      (tester) async {
        // Given
        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentRadarrInstanceProvider.overrideWithValue(null),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: MoviePoster(movie: testMovieWithRemotePoster),
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();

            // Then
            expect(find.byType(MoviePoster), findsOneWidget);
            expect(find.byIcon(Icons.movie_outlined), findsNothing);
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
          type: InstanceType.radarr,
          url: 'http://localhost:7878',
          apiKey: 'test-api-key',
        );

        await HttpOverrides.runZoned(
          () async {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  currentRadarrInstanceProvider.overrideWithValue(testInstance),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 100,
                      height: 150,
                      child: MoviePoster(movie: testMovieWithRemotePoster),
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();

            // Then
            expect(find.byType(MoviePoster), findsOneWidget);
            expect(find.byIcon(Icons.movie_outlined), findsNothing);
          },
          createHttpClient: (context) =>
              TestHttpOverrides().createHttpClient(context),
        );
      },
    );
  });
}
