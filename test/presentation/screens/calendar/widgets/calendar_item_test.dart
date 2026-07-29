import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/queue_lookup_provider.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:arrmate/presentation/screens/calendar/widgets/calendar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should select the event origin before opening movie details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        queueMediaLookupProvider.overrideWithValue(
          const AsyncValue.data(QueueMediaLookup()),
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
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movie'));
    await tester.pumpAndSettle();

    expect(container.read(currentRadarrInstanceProvider), remote);
    expect(find.text('Movie details 42'), findsOneWidget);
  });

  testWidgets(
    'should open the exact episode route when tapping an episode event',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          queueMediaLookupProvider.overrideWithValue(
            const AsyncValue.data(QueueMediaLookup()),
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
          child: MaterialApp.router(routerConfig: router),
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

Movie _movie() {
  return Movie(
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
