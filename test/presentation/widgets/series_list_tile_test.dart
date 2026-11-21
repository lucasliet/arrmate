import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/series/widgets/series_list_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/localized_app.dart';

void main() {
  final series = Series(
    guid: 9,
    title: 'Test Series',
    sortTitle: 'Test Series',
    tvdbId: 371980,
    imdbId: 'tt11280740',
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2024,
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

  testWidgets('SeriesListTile should preserve long press selection', (
    tester,
  ) async {
    // Given
    var longPressed = false;
    await tester.pumpWidget(
      wrap(
        SeriesListTile(series: series, onLongPress: () => longPressed = true),
      ),
    );

    // When
    await tester.longPress(find.text('Test Series'));

    // Then
    expect(longPressed, isTrue);
  });

  testWidgets('SeriesListTile should render title and season count', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(SeriesListTile(series: series)));

    expect(find.text('Test Series'), findsOneWidget);
    expect(find.text('0 Seasons'), findsOneWidget);
  });

  testWidgets(
    'SeriesListTile should render the poster with the framework image on web',
    (tester) async {
      // Given
      const posterUrl = 'https://image.tmdb.org/t/p/w500/poster.jpg';
      final withPoster = Series(
        guid: 9,
        title: 'Test Series',
        sortTitle: 'Test Series',
        tvdbId: 371980,
        status: SeriesStatus.continuing,
        seriesType: SeriesType.standard,
        year: 2024,
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
        wrap(SeriesListTile(series: withPoster), isWeb: true),
      );

      // Then
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, posterUrl);
      expect(find.byType(CachedNetworkImage), findsNothing);
    },
  );
}
