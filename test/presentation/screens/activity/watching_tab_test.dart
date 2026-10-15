import 'dart:async';

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
import 'package:arrmate/presentation/screens/player/playback_request.dart';
import 'package:arrmate/presentation/screens/player/playback_stop_gate.dart';

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
  final List<WatchingItem> _nextUp;
  final void Function()? _onBuild;

  _StubWatchingNotifier(
    this._items, {
    List<WatchingItem> nextUp = const [],
    void Function()? onBuild,
  }) : _nextUp = nextUp,
       _onBuild = onBuild;

  @override
  Future<WatchingFeed> build() async {
    _onBuild?.call();
    return WatchingFeed(continueWatching: _items, nextUp: _nextUp);
  }
}

class _StubInstancesNotifier extends InstancesNotifier {
  final bool failSelection;

  _StubInstancesNotifier({this.failSelection = false});

  @override
  InstancesState build() => const InstancesState(isLoading: false);

  @override
  Future<void> selectInstance(InstanceType type, String id) async {
    if (failSelection) throw StateError('Instance selection failed');
  }
}

class _FakePlaybackLaunchService extends PlaybackLaunchService {
  JellyfinItem? lastPlayedItem;
  String? lastPlayedTitle;

  /// When set, [playItem] reports a launched player that closes with this
  /// future; otherwise it reports a cancelled launch.
  ///
  /// This future is independent of the route pushed when [pushPlayerRoute]
  /// is true, so a test can pop that route while the future stays pending.
  Future<void>? launchedClosed;

  /// When true, [playItem] pushes `/player` without exposing that navigation
  /// future as [PlaybackLaunched.closed].
  bool pushPlayerRoute = false;

  @override
  Future<PlaybackLaunchResult> playItem(
    BuildContext context,
    WidgetRef ref, {
    required JellyfinItem item,
    String? title,
  }) async {
    lastPlayedItem = item;
    lastPlayedTitle = title;
    final request = PlaybackRequest(
      title: title ?? item.name ?? '',
      streamUrl: Uri.parse('http://jellyfin.local:8096/Videos/jf/stream'),
    );
    if (pushPlayerRoute) {
      unawaited(context.push<void>('/player', extra: request));
    }
    final closed = launchedClosed;
    if (closed == null && !pushPlayerRoute) {
      return const PlaybackLaunchCancelled();
    }
    return PlaybackLaunched(request, closed: closed);
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

  final nextUpWatchingItem = WatchingItem(
    jellyfinItem: const JellyfinItem(
      id: 'jf-ep-99-next',
      name: 'Half Loop',
      seriesName: 'Severance',
      type: 'Episode',
      parentIndexNumber: 1,
      indexNumber: 2,
      runTimeTicks: 50 * 60 * 10000000,
      mediaSources: [JellyfinMediaSource(id: 'ms-99-next')],
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

    testWidgets(
      'renders Next Up below Continue Watching with a next episode footer',
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
                () => _StubWatchingNotifier(
                  [movieWatchingItem],
                  nextUp: [nextUpWatchingItem],
                ),
              ),
            ],
            child: const MaterialApp(home: ActivityScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // When
        await tester.tap(find.widgetWithText(Tab, 'Watching'));
        await tester.pumpAndSettle();

        // Then
        final continueHeader = find.text('Continue Watching');
        final nextUpHeader = find.text('Next Up');
        expect(continueHeader, findsOneWidget);
        expect(nextUpHeader, findsOneWidget);
        expect(find.byType(WatchingListItem), findsNWidgets(2));
        expect(
          tester.getTopLeft(nextUpHeader).dy,
          greaterThan(tester.getTopLeft(find.text('Blade Runner 2049')).dy),
        );
        expect(
          tester.getTopLeft(find.text('S01E02 · Half Loop')).dy,
          greaterThan(tester.getTopLeft(nextUpHeader).dy),
        );
        expect(find.text('Next episode · 50m'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('shows Watching tab when only Next Up has items', (
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
              () =>
                  _StubWatchingNotifier(const [], nextUp: [nextUpWatchingItem]),
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
      expect(find.text('Continue Watching'), findsNothing);
      expect(find.text('Next Up'), findsOneWidget);
      expect(find.byType(WatchingListItem), findsOneWidget);
    });

    testWidgets('tapping a Next Up item starts playback via playItem', (
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
              () =>
                  _StubWatchingNotifier(const [], nextUp: [nextUpWatchingItem]),
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
      expect(fakeLaunchService.lastPlayedItem?.id, 'jf-ep-99-next');
      expect(
        fakeLaunchService.lastPlayedTitle,
        'Severance · S01E02 · Half Loop',
      );
    });

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
              instancesProvider.overrideWith(() => _StubInstancesNotifier()),
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

    testWidgets(
      'refetches watching items once when the location leaves /player',
      (tester) async {
        // Given
        final harness = await _pumpActivityShell(
          tester,
          jellyfinInstance: jellyfinInstance,
          item: episodeWatchingItem,
          player: const Scaffold(body: Text('Player')),
        );

        // When
        await tester.tap(find.byType(WatchingListItem));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player'), findsOneWidget);
        expect(harness.buildCount, harness.buildsBeforePlay);

        // When: browser Back updates the location without popping.
        harness.router.go('/activity');
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player'), findsNothing);
        expect(harness.buildCount, harness.buildsBeforePlay + 1);
        expect(harness.unresolvedClose.isCompleted, isFalse);
      },
    );

    testWidgets('refetches watching items once when /player is popped', (
      tester,
    ) async {
      // Given
      final harness = await _pumpActivityShell(
        tester,
        jellyfinInstance: jellyfinInstance,
        item: episodeWatchingItem,
        player: const Scaffold(body: Text('Player')),
      );

      // When
      await tester.tap(find.byType(WatchingListItem));
      await tester.pumpAndSettle();
      harness.router.pop();
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Player'), findsNothing);
      expect(harness.buildCount, harness.buildsBeforePlay + 1);
      expect(harness.unresolvedClose.isCompleted, isFalse);

      await tester.pump(const Duration(milliseconds: 50));
      expect(harness.buildCount, harness.buildsBeforePlay + 1);
    });

    testWidgets(
      'refetches watching items once when the player back button pops',
      (tester) async {
        // Given
        final harness = await _pumpActivityShell(
          tester,
          jellyfinInstance: jellyfinInstance,
          item: episodeWatchingItem,
          player: Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: const Text('Player'),
          ),
        );

        // When
        await tester.tap(find.byType(WatchingListItem));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player'), findsNothing);
        expect(harness.buildCount, harness.buildsBeforePlay + 1);
        expect(harness.unresolvedClose.isCompleted, isFalse);

        await tester.pump(const Duration(milliseconds: 50));
        expect(harness.buildCount, harness.buildsBeforePlay + 1);
      },
    );

    testWidgets(
      'refetches watching items after the stop report when leaving /player',
      (tester) async {
        // Given
        final release = Completer<void>();
        final events = <String>[];
        final stop = release.future.then((_) {
          events.add('stopped');
        });
        final harness = await _pumpActivityShell(
          tester,
          jellyfinInstance: jellyfinInstance,
          item: episodeWatchingItem,
          player: _StopReportingPlayer(stop: stop),
          onBuild: () => events.add('resume'),
        );
        final resumesBeforeLeave = events.length;

        // When
        await tester.tap(find.byType(WatchingListItem));
        await tester.pumpAndSettle();
        harness.router.pop();
        await tester.pumpAndSettle();

        // Then
        expect(events.length, resumesBeforeLeave);

        // When
        release.complete();
        await tester.pumpAndSettle();

        // Then
        expect(events.sublist(resumesBeforeLeave), ['stopped', 'resume']);
        expect(harness.buildCount, harness.buildsBeforePlay + 1);
      },
    );

    testWidgets('does not navigate to library when instance selection fails', (
      tester,
    ) async {
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
            currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
            currentQBittorrentInstanceProvider.overrideWithValue(null),
            queueProvider.overrideWith(_EmptyQueueNotifier.new),
            activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
            watchingItemsProvider.overrideWith(
              () => _StubWatchingNotifier([movieWatchingItem]),
            ),
            instancesProvider.overrideWith(
              () => _StubInstancesNotifier(failSelection: true),
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
      expect(navigatedLocation, isNull);
      expect(find.text('Movie Details'), findsNothing);
      expect(find.byType(WatchingListItem), findsOneWidget);
    });
  });
}

class _ShellHarness {
  _ShellHarness(this.router, this.unresolvedClose);

  final GoRouter router;
  final Completer<void> unresolvedClose;
  int buildCount = 0;
  int buildsBeforePlay = 0;
}

/// Pumps Activity inside a shell, with `/player` on the root navigator.
Future<_ShellHarness> _pumpActivityShell(
  WidgetTester tester, {
  required Instance jellyfinInstance,
  required WatchingItem item,
  required Widget player,
  void Function()? onBuild,
}) async {
  final rootKey = GlobalKey<NavigatorState>();
  final unresolvedClose = Completer<void>();
  final fakeLaunchService = _FakePlaybackLaunchService()
    ..pushPlayerRoute = true
    ..launchedClosed = unresolvedClose.future;
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/activity',
    routes: [
      GoRoute(
        path: '/player',
        parentNavigatorKey: rootKey,
        builder: (context, state) => player,
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/activity',
            builder: (context, state) => const ActivityScreen(),
          ),
        ],
      ),
    ],
  );
  final ready = _ShellHarness(router, unresolvedClose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentJellyfinInstanceProvider.overrideWithValue(jellyfinInstance),
        currentQBittorrentInstanceProvider.overrideWithValue(null),
        queueProvider.overrideWith(_EmptyQueueNotifier.new),
        activityHistoryProvider.overrideWith(_EmptyHistoryNotifier.new),
        watchingItemsProvider.overrideWith(
          () => _StubWatchingNotifier(
            [item],
            onBuild: () {
              ready.buildCount++;
              onBuild?.call();
            },
          ),
        ),
        playbackLaunchServiceProvider.overrideWithValue(fakeLaunchService),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(Tab, 'Watching'));
  await tester.pumpAndSettle();
  ready.buildsBeforePlay = ready.buildCount;
  return ready;
}

/// Registers [stop] on the playback gate when the player route is disposed.
class _StopReportingPlayer extends ConsumerStatefulWidget {
  const _StopReportingPlayer({required this.stop});

  final Future<void> stop;

  @override
  ConsumerState<_StopReportingPlayer> createState() =>
      _StopReportingPlayerState();
}

class _StopReportingPlayerState extends ConsumerState<_StopReportingPlayer> {
  late final PlaybackStopGate _gate;

  @override
  void initState() {
    super.initState();
    _gate = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(playbackStopGateProvider);
    _gate.arm();
  }

  @override
  void dispose() {
    _gate.track(widget.stop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Player'));
  }
}
