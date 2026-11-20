import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/movies/widgets/movie_list_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/localized_app.dart';

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

  Widget wrap(Widget child, {bool isWeb = false}) {
    return ProviderScope(
      overrides: [
        queueMediaLookupProvider.overrideWithValue(
          const AsyncValue.data(QueueMediaLookup.empty),
        ),
        platformCapabilitiesProvider.overrideWithValue(
          PlatformCapabilities.forPlatform(
            isWeb: isWeb,
            targetPlatform: TargetPlatform.linux,
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        locale: testLocale,
        home: Scaffold(body: child),
      ),
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

  testWidgets(
    'MovieListTile should render the poster with the framework image on web',
    (tester) async {
      // Given
      const posterUrl = 'https://image.tmdb.org/t/p/w500/poster.jpg';
      final withPoster = Movie(
        guid: 7,
        tmdbId: 123,
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
        images: [
          MediaImage(
            coverType: 'poster',
            url: '/poster.jpg',
            remoteUrl: posterUrl,
          ),
        ],
      );

      // When
      await tester.pumpWidget(
        wrap(MovieListTile(movie: withPoster), isWeb: true),
      );

      // Then
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, posterUrl);
      expect(find.byType(CachedNetworkImage), findsNothing);
    },
  );
}
