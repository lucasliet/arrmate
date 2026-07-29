import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/series/episode_route_screen.dart';
import 'package:arrmate/presentation/screens/series/providers/season_episodes_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'should open the episode details sheet once episodes are resolved',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          seriesDetailsProvider(9).overrideWith((ref) async => _series()),
          seasonEpisodesProvider(9, 3).overrideWith(
            (ref) async => [
              Episode(
                id: 1,
                seriesId: 9,
                seasonNumber: 3,
                episodeNumber: 1,
                title: 'Other',
              ),
              Episode(
                id: 77,
                seriesId: 9,
                seasonNumber: 3,
                episodeNumber: 5,
                title: 'Pilot',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EpisodeRouteScreen(
              seriesId: 9,
              seasonNumber: 3,
              episodeId: 77,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('S03E05 - Pilot'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'should not crash when the requested episode is not in the season',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          seriesDetailsProvider(9).overrideWith((ref) async => _series()),
          seasonEpisodesProvider(9, 3).overrideWith(
            (ref) async => [
              Episode(
                id: 1,
                seriesId: 9,
                seasonNumber: 3,
                episodeNumber: 1,
                title: 'Only',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EpisodeRouteScreen(
              seriesId: 9,
              seasonNumber: 3,
              episodeId: 999,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Series - Season 3'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

Series _series() {
  return Series(
    guid: 9,
    title: 'Series',
    sortTitle: 'series',
    tvdbId: 12345,
    seasons: [Season(seasonNumber: 3, monitored: true)],
    monitored: true,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2024,
    qualityProfileId: 1,
    added: DateTime(2024),
  );
}
