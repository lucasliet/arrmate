import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:arrmate/core/services/playback_launch_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/activity/activity_screen.dart';
import 'package:arrmate/presentation/screens/activity/providers/activity_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/history_provider.dart';
import 'package:arrmate/presentation/screens/activity/providers/watching_provider.dart';
import 'package:arrmate/presentation/screens/activity/widgets/watching_list_item.dart';

class _EmptyQueueNotifier extends QueueNotifier {
  @override
  Future<List<QueueItem>> build() async => const [];
}

class _EmptyHistoryNotifier extends HistoryNotifier {
  @override
  Future<List<HistoryEvent>> build() async => const [];
}

class _StubWatchingNotifier extends WatchingNotifier {
  final List<WatchingItem> _items;

  _StubWatchingNotifier(this._items);

  @override
  Future<List<WatchingItem>> build() async => _items;
}

class _FakePlaybackLaunchService extends PlaybackLaunchService {
  JellyfinItem? lastPlayedItem;
  String? lastPlayedTitle;

  @override
  Future<PlaybackLaunchResult> playItem(
    BuildContext context,
    WidgetRef ref, {
    required JellyfinItem item,
    String? title,
  }) async {
    lastPlayedItem = item;
    lastPlayedTitle = title;
    return const PlaybackLaunchCancelled();
  }
}

void main() {
  final jellyfinInstance = Instance(
    id: 'jf-1',
    label: 'Jellyfin',
    url: 'http://jellyfin.local:8096',
    apiKey: 'token-1',
    type: InstanceType.jellyfin,
  );

  final radarrInstance = Instance(
    id: 'radarr-1',
    label: 'Radarr',
    url: 'http://radarr.local:7878',
    apiKey: 'radarr-key',
    type: InstanceType.radarr,
  );

  final sonarrInstance = Instance(
    id: 'sonarr-1',
    label: 'Sonarr',
    url: 'http://sonarr.local:8989',
    apiKey: 'sonarr-key',
    type: InstanceType.sonarr,
  );

  final sampleMovie = Movie.fromJson({
    'id': 42,
    'title': 'Blade Runner 2049',
    'sortTitle': 'blade runner 2049',
    'year': 2017,
    'tmdbId': 335984,
    'status': 'released',
    'monitored': true,
    'minimumAvailability': 'released',
    'hasFile': true,
    'sizeOnDisk': 1024,
    'runtime': 164,
    'added': '2024-01-01T00:00:00Z',
    'qualityProfileId': 1,
  });

  final sampleSeries = Series.fromJson({
    'id': 99,
    'title': 'Severance',
    'sortTitle': 'severance',
    'status': 'continuing',
    'ended': false,
    'year': 2022,
    'tvdbId': 371980,
    'monitored': true,
    'useSceneNumbering': false,
    'runtime': 50,
    'added': '2024-01-01T00:00:00Z',
    'qualityProfileId': 1,
    'seasonFolder': true,
    'seriesType': 'standard',
    'cleanTitle': 'severance',
    'titleSlug': 'severance',
  });

  final movieWatchingItem = WatchingItem(
    jellyfinItem: const JellyfinItem(
      id: 'jf-movie-42',
      name: 'Blade Runner 2049',
      type: 'Movie',
      runTimeTicks: 100 * 60 * 10000000,
      playbackPositionTicks: 45 * 60 * 10000000,
      mediaSources: [JellyfinMediaSource(id: 'ms-42')],
    ),
    mediaInstance: radarrInstance,
    movie: sampleMovie,
  );

  final episodeWatchingItem = WatchingItem(
    jellyfinItem: const JellyfinItem(
      id: 'jf-ep-99',
      name: 'Good News About Hell',
      seriesName: 'Severance',
      type: 'Episode',
      parentIndexNumber: 1,
      indexNumber: 1,
      runTimeTicks: 50 * 60 * 10000000,
      playbackPositionTicks: 25 * 60 * 10000000,
      mediaSources: [JellyfinMediaSource(id: 'ms-99')],
    ),
    mediaInstance: sonarrInstance,
    series: sampleSeries,
  );

  group('ActivityScreen Watching tab', () {
    testWidgets('hides Watching tab when Jellyfin is not configured', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(null),
            currentQBittorrentInstanceProvider.overrideWithValue(null),
            queueProvider.overrideWith(_EmptyQueueNotifier.new),
            activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
            watchingItemsProvider.overrideWith(
              () => _StubWatchingNotifier([movieWatchingItem]),
            ),
          ],
          child: const MaterialApp(home: ActivityScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // When / Then
      expect(find.widgetWithText(Tab, 'Watching'), findsNothing);
    });

    testWidgets('hides Watching tab when matched resume list is empty', (
      tester,
    ) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
            currentQBittorrentInstanceProvider.overrideWithValue(null),
            queueProvider.overrideWith(_EmptyQueueNotifier.new),
            activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
            watchingItemsProvider.overrideWith(
              () => _StubWatchingNotifier(const []),
            ),
          ],
          child: const MaterialApp(home: ActivityScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // When / Then
      expect(find.widgetWithText(Tab, 'Watching'), findsNothing);
    });

    testWidgets(
      'shows Watching tab and renders movie and episode cards with progress',
      (tester) async {
        // Given
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentJellyfinInstanceProvider.overrideWithValue(
                jellyfinInstance,
              ),
              currentQBittorrentInstanceProvider.overrideWithValue(null),
              queueProvider.overrideWith(_EmptyQueueNotifier.new),
              activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
              watchingItemsProvider.overrideWith(
                () => _StubWatchingNotifier([
                  movieWatchingItem,
                  episodeWatchingItem,
                ]),
              ),
            ],
            child: const MaterialApp(home: ActivityScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final watchingTab = find.widgetWithText(Tab, 'Watching');
        expect(watchingTab, findsOneWidget);

        // When
        await tester.tap(watchingTab);
        await tester.pumpAndSettle();

        // Then
        expect(find.byType(WatchingListItem), findsNWidgets(2));
        expect(find.text('Blade Runner 2049'), findsOneWidget);
        expect(find.text('Severance'), findsOneWidget);
        expect(find.text('S01E01 · Good News About Hell'), findsOneWidget);
        expect(find.text('45%'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      },
    );

    testWidgets('tapping WatchingListItem resumes playback via playItem', (
      tester,
    ) async {
      // Given
      final fakeLaunchService = _FakePlaybackLaunchService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
            currentQBittorrentInstanceProvider.overrideWithValue(null),
            queueProvider.overrideWith(_EmptyQueueNotifier.new),
            activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
            watchingItemsProvider.overrideWith(
              () => _StubWatchingNotifier([episodeWatchingItem]),
            ),
            playbackLaunchServiceProvider.overrideWithValue(fakeLaunchService),
          ],
          child: const MaterialApp(home: ActivityScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Watching'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(WatchingListItem));
      await tester.pumpAndSettle();

      // Then
      expect(fakeLaunchService.lastPlayedItem?.id, 'jf-ep-99');
      expect(
        fakeLaunchService.lastPlayedTitle,
        'Severance · S01E01 · Good News About Hell',
      );
    });

    testWidgets(
      'tapping Open in library button navigates to movie details route',
      (tester) async {
        // Given
        String? navigatedLocation;
        final router = GoRouter(
          initialLocation: '/activity',
          routes: [
            GoRoute(
              path: '/activity',
              builder: (context, state) => const ActivityScreen(),
            ),
            GoRoute(
              path: '/movies/:id',
              builder: (context, state) {
                navigatedLocation = state.uri.toString();
                return const Scaffold(body: Text('Movie Details'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentJellyfinInstanceProvider.overrideWithValue(
                jellyfinInstance,
              ),
              currentQBittorrentInstanceProvider.overrideWithValue(null),
              queueProvider.overrideWith(_EmptyQueueNotifier.new),
              activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
              watchingItemsProvider.overrideWith(
                () => _StubWatchingNotifier([movieWatchingItem]),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(Tab, 'Watching'));
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.byTooltip('Open in library'));
        await tester.pumpAndSettle();

        // Then
        expect(navigatedLocation, '/movies/42');
        expect(find.text('Movie Details'), findsOneWidget);
      },
    );
  });
}
