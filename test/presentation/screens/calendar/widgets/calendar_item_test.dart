import 'package:arrmate/core/platform/platform_capabilities.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:arrmate/presentation/screens/calendar/widgets/calendar_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/localized_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should select the event origin before opening movie details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        queueMediaLookupProvider.overrideWithValue(
          const AsyncValue.data(QueueMediaLookup.empty),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _waitUntilLoaded(tester, container);
    final home = _instance('radarr-home');
    final remote = _instance('radarr-remote');
    final notifier = container.read(instancesProvider.notifier);
    await notifier.addInstance(home);
    await notifier.addInstance(remote);
    await notifier.selectInstance(InstanceType.radarr, home.id);
    final event = CalendarEvent(
      instanceId: remote.id,
      instanceType: remote.type,
      releaseDate: DateTime.now(),
      type: CalendarEventType.digital,
      movie: _movie(),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: CalendarItem(event: event)),
        ),
        GoRoute(
          path: '/movies/:id',
          builder: (context, state) =>
              Text('Movie details ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movie'));
    await tester.pumpAndSettle();

    expect(container.read(currentRadarrInstanceProvider), remote);
    expect(find.text('Movie details 42'), findsOneWidget);
  });

  testWidgets('should render the poster with the framework image on web', (
    tester,
  ) async {
    // Given
    const posterUrl = 'https://image.tmdb.org/t/p/w500/poster.jpg';
    final event = CalendarEvent(
      instanceId: 'radarr-home',
      instanceType: InstanceType.radarr,
      releaseDate: DateTime.now(),
      type: CalendarEventType.digital,
      movie: _movie(
        images: [
          MediaImage(
            coverType: 'poster',
            url: '/poster.jpg',
            remoteUrl: posterUrl,
          ),
        ],
      ),
    );

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          queueMediaLookupProvider.overrideWithValue(
            const AsyncValue.data(QueueMediaLookup.empty),
          ),
          platformCapabilitiesProvider.overrideWithValue(
            PlatformCapabilities.forPlatform(
              isWeb: true,
              targetPlatform: TargetPlatform.linux,
            ),
          ),
          instancesProvider.overrideWith(_NoInstancesNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: testLocale,
          home: Scaffold(body: CalendarItem(event: event)),
        ),
      ),
    );

    // Then
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, posterUrl);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets(
    'should open the exact episode route when tapping an episode event',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          queueMediaLookupProvider.overrideWithValue(
            const AsyncValue.data(QueueMediaLookup.empty),
          ),
        ],
      );
      addTearDown(container.dispose);
      await _waitUntilLoaded(tester, container);
      final home = _instance('sonarr-home', type: InstanceType.sonarr);
      final remote = _instance('sonarr-remote', type: InstanceType.sonarr);
      final notifier = container.read(instancesProvider.notifier);
      await notifier.addInstance(home);
      await notifier.addInstance(remote);
      await notifier.selectInstance(InstanceType.sonarr, home.id);
      final event = CalendarEvent(
        instanceId: remote.id,
        instanceType: remote.type,
        releaseDate: DateTime.now(),
        type: CalendarEventType.episode,
        episode: Episode(
          id: 77,
          seriesId: 9,
          seasonNumber: 3,
          episodeNumber: 5,
          title: 'Pilot',
        ),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                Scaffold(body: CalendarItem(event: event)),
          ),
          GoRoute(
            path: '/series/:id/season/:season/episode/:episode',
            builder: (context, state) => Text(
              'Episode route '
              '${state.pathParameters['id']} '
              '${state.pathParameters['season']} '
              '${state.pathParameters['episode']}',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            locale: testLocale,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Pilot'));
      await tester.pumpAndSettle();

      expect(container.read(currentSonarrInstanceProvider), remote);
      expect(find.text('Episode route 9 3 77'), findsOneWidget);
    },
  );
}

Future<void> _waitUntilLoaded(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(instancesProvider);
  var attempts = 0;
  while (container.read(instancesProvider).isLoading) {
    if (attempts++ >= 100) {
      throw StateError('Instances did not load');
    }
    await tester.pump(const Duration(milliseconds: 1));
  }
}

Instance _instance(String id, {InstanceType type = InstanceType.radarr}) {
  return Instance(
    id: id,
    type: type,
    label: id,
    url: 'https://$id.example.com',
    apiKey: 'key',
  );
}

Movie _movie({List<MediaImage> images = const []}) {
  return Movie(
    images: images,
    guid: 42,
    tmdbId: 1,
    title: 'Movie',
    sortTitle: 'movie',
    year: 2026,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    added: DateTime.now(),
  );
}

/// Instances state with nothing configured and nothing to load.
class _NoInstancesNotifier extends InstancesNotifier {
  @override
  InstancesState build() => const InstancesState(isLoading: false);
}
