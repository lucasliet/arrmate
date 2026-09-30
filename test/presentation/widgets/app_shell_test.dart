import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/network_status_provider.dart';
import 'package:arrmate/presentation/screens/discovery/discovery_screen.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/widgets/app_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('uses platform navigation without duplicate page headers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/movies',
              builder: (context, state) =>
                  Scaffold(appBar: AppBar(title: const Text('Page title'))),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkAvailabilityProvider.overrideWith(
            (ref) => const Stream<NetworkAvailability>.empty(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page title'), findsOneWidget);
    expect(find.byType(NavigationBar), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.byType(NavigationRail), kIsWeb ? findsOneWidget : findsNothing);
    expect(find.text('ARRMATE'), kIsWeb ? findsOneWidget : findsNothing);
    expect(find.byTooltip('Search'), findsNothing);
  });

  testWidgets('rail survives pushing and popping a full-screen route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/movies',
              builder: (context, state) => const MoviesScreen(),
            ),
            GoRoute(
              path: '/discover',
              builder: (context, state) => DiscoveryScreen(
                initialType: state.uri.queryParameters['type'] ?? 'movie',
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkAvailabilityProvider.overrideWith(
            (ref) => const Stream<NetworkAvailability>.empty(),
          ),
          currentRadarrInstanceProvider.overrideWithValue(null),
          currentSonarrInstanceProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.push('/discover');
    await tester.pumpAndSettle();

    final close = find.byIcon(Icons.close);
    final bell = find.byIcon(Icons.notifications_outlined);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    if (tester.any(bell)) {
      await gesture.moveTo(tester.getCenter(bell.first));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.tap(close);
    await gesture.moveTo(tester.getCenter(close));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.removePointer();

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MoviesScreen), findsOneWidget);
  });
}
