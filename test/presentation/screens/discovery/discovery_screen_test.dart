import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/discovery/discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('should show only the movie add flow for movie discovery', (
    tester,
  ) async {
    const screen = DiscoveryScreen(initialType: 'movie');

    await tester.pumpWidget(_wrap(screen));

    expect(find.text('Add Movie'), findsOneWidget);
    expect(find.text('Add Series'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('should show only the series add flow for series discovery', (
    tester,
  ) async {
    const screen = DiscoveryScreen(initialType: 'series');

    await tester.pumpWidget(_wrap(screen));

    expect(find.text('Add Series'), findsOneWidget);
    expect(find.text('Add Movie'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets(
    'should fall back to the library route when closing the movie flow as root',
    (tester) async {
      // Given
      final router = GoRouter(
        initialLocation: '/discover',
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoveryScreen(),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                const Scaffold(body: Text('Movies library')),
          ),
          GoRoute(
            path: '/series',
            builder: (context, state) =>
                const Scaffold(body: Text('Series library')),
          ),
        ],
      );
      addTearDown(router.dispose);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRadarrInstanceProvider.overrideWithValue(null),
            currentSonarrInstanceProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then
      expect(tester.takeException(), isNull);
      expect(find.text('Movies library'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/movies');
    },
  );

  testWidgets(
    'should fall back to the series route when closing the series flow as root',
    (tester) async {
      // Given
      final router = GoRouter(
        initialLocation: '/discover?type=series',
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => DiscoveryScreen(
              initialType: state.uri.queryParameters['type'] ?? 'movie',
            ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                const Scaffold(body: Text('Movies library')),
          ),
          GoRoute(
            path: '/series',
            builder: (context, state) =>
                const Scaffold(body: Text('Series library')),
          ),
        ],
      );
      addTearDown(router.dispose);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRadarrInstanceProvider.overrideWithValue(null),
            currentSonarrInstanceProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then
      expect(tester.takeException(), isNull);
      expect(find.text('Series library'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/series');
    },
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      currentRadarrInstanceProvider.overrideWithValue(null),
      currentSonarrInstanceProvider.overrideWithValue(null),
    ],
    child: MaterialApp(home: child),
  );
}
