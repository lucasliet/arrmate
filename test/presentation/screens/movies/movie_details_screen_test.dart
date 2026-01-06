import 'package:arrmate/domain/models/models.dart';

import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/movies/movie_details_screen.dart';
import 'package:arrmate/presentation/screens/movies/providers/movie_details_provider.dart';
import 'package:arrmate/presentation/screens/movies/providers/movie_metadata_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock models
final mockInstance = Instance(
  id: '1',
  name: 'Test Instance',
  url: 'http://localhost:7878',
  apiKey: 'apikey',
  type: InstanceType.radarr,
);

Movie createMockMovie({List<MediaImage> images = const []}) {
  return Movie(
    tmdbId: 123,
    title: 'Test Movie',
    sortTitle: 'Test Movie',
    year: 2023,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    added: DateTime.now(),
    images: images,
    genres: ['Action'],
    tags: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MovieDetailsScreen should prefer remoteUrl for background if available',
    (tester) async {
      const remoteUrl = 'http://remote.com/image.jpg';
      final movie = createMockMovie(
        images: [
          MediaImage(
            coverType: 'fanart',
            url: '/local/image.jpg',
            remoteUrl: remoteUrl,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRadarrInstanceProvider.overrideWithValue(mockInstance),
            movieDetailsProvider(1).overrideWith((ref) => movie),
            movieFilesProvider(1).overrideWith((ref) async => []),
            movieExtraFilesProvider(1).overrideWith((ref) async => []),
            movieHistoryProvider(1).overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: MovieDetailsScreen(movieId: 1)),
        ),
      );

      await tester.pump();

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
    'MovieDetailsScreen should fall back to local URL with auth headers if remoteUrl is missing',
    (tester) async {
      const localUrl = '/local/image.jpg';
      final movie = createMockMovie(
        images: [
          MediaImage(coverType: 'fanart', url: localUrl, remoteUrl: null),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRadarrInstanceProvider.overrideWithValue(mockInstance),
            movieDetailsProvider(1).overrideWith((ref) => movie),
            movieFilesProvider(1).overrideWith((ref) async => []),
            movieExtraFilesProvider(1).overrideWith((ref) async => []),
            movieHistoryProvider(1).overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: MovieDetailsScreen(movieId: 1)),
        ),
      );

      await tester.pump();

      final expectedUrl = 'http://localhost:7878/local/image.jpg';

      final imageFinder = find.byWidgetPredicate((widget) {
        if (widget is CachedNetworkImage) {
          return widget.imageUrl == expectedUrl &&
              widget.httpHeaders?['X-Api-Key'] == 'apikey';
        }
        return false;
      });

      expect(imageFinder, findsOneWidget);
    },
  );

  testWidgets(
    'MovieDetailsScreen should show fallback container if no images',
    (tester) async {
      final movie = createMockMovie(images: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRadarrInstanceProvider.overrideWithValue(mockInstance),
            movieDetailsProvider(1).overrideWith((ref) => movie),
            movieFilesProvider(1).overrideWith((ref) async => []),
            movieExtraFilesProvider(1).overrideWith((ref) async => []),
            movieHistoryProvider(1).overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: MovieDetailsScreen(movieId: 1)),
        ),
      );

      await tester.pump();

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
}
