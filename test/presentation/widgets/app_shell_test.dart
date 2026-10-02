import 'package:arrmate/presentation/adaptive/content_layout.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/providers/network_status_provider.dart';
import 'package:arrmate/presentation/screens/discovery/discovery_screen.dart';
import 'package:arrmate/presentation/screens/movies/movies_screen.dart';
import 'package:arrmate/presentation/widgets/app_shell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets the logical window size seen by both [MediaQuery] and layout.
///
/// [WidgetTester.binding.setSurfaceSize] updates render constraints only. The
/// shell reads [MediaQuery.sizeOf], which follows the test view.
Future<void> _setWindowSize(WidgetTester tester, Size? size) async {
  if (size == null) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  } else {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
  }
  await tester.binding.setSurfaceSize(size);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets('resizing on $platform preserves page and navigation state', (
      tester,
    ) async {
      addTearDown(() => _setWindowSize(tester, null));
      final router = GoRouter(
        initialLocation: '/series',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/series',
                builder: (context, state) => AdaptiveLayout(
                  builder: (context) => Scaffold(
                    body: Column(
                      children: [
                        Text('width:${ContentLayout.of(context).width}'),
                        const TextField(),
                        Expanded(
                          child: ListView.builder(
                            itemCount: 100,
                            itemExtent: 48,
                            itemBuilder: (context, index) =>
                                Text('Item $index'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await _setWindowSize(tester, const Size(599, 500));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkAvailabilityProvider.overrideWith(
              (ref) => const Stream<NetworkAvailability>.empty(),
            ),
          ],
          child: MaterialApp.router(
            theme: ThemeData(platform: platform),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep this draft');
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      final originalState = tester.state(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      final position = (originalState as ScrollableState).position.pixels;

      for (final width in [
        600.0,
        899.0,
        900.0,
        1439.0,
        1440.0,
        2200.0,
        599.0,
      ]) {
        await _setWindowSize(tester, Size(width, 500));
        await tester.pumpAndSettle();
        final rail = find.byType(NavigationRail);
        if (width < 600) {
          expect(rail, findsNothing);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            1,
          );
        } else {
          expect(find.byType(NavigationBar), findsNothing);
          final navigation = tester.widget<NavigationRail>(rail);
          expect(navigation.extended, width >= 900);
          expect(navigation.selectedIndex, 1);
        }
        final contentWidth = tester.getSize(find.byType(TextField)).width;
        final expectedWidth = width < 600
            ? width
            : (width - tester.getSize(rail).width - 1).clamp(0, 1600);
        expect(contentWidth, closeTo(expectedWidth, 0.01));
        expect(find.text('width:$contentWidth'), findsOneWidget);
        expect(find.text('Keep this draft'), findsOneWidget);
        final scrollable = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        );
        expect(tester.state(scrollable), same(originalState));
        expect(
          (tester.state(scrollable) as ScrollableState).position.pixels,
          position,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('uses available width without duplicate page headers', (
    tester,
  ) async {
    await _setWindowSize(tester, const Size(1400, 900));
    addTearDown(() => _setWindowSize(tester, null));

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
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('ARRMATE'), findsOneWidget);
    expect(find.byTooltip('Search'), findsNothing);
  });

  testWidgets('rail survives pushing and popping a full-screen route', (
    tester,
  ) async {
    await _setWindowSize(tester, const Size(1400, 900));
    addTearDown(() => _setWindowSize(tester, null));

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

  testWidgets('route changes build pages outside the shell layout pass', (
    tester,
  ) async {
    await _setWindowSize(tester, const Size(1400, 900));
    addTearDown(() => _setWindowSize(tester, null));

    var moviesBuiltDuringLayout = false;
    var discoverBuiltDuringLayout = false;

    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/movies',
              pageBuilder: (context, state) => NoTransitionPage(
                child: _LayoutPhaseProbe(
                  label: 'Movies',
                  tooltip: 'Notifications',
                  onBuild: (duringLayout) {
                    moviesBuiltDuringLayout = duringLayout;
                  },
                ),
              ),
            ),
            GoRoute(
              path: '/discover',
              builder: (context, state) => _LayoutPhaseProbe(
                label: 'Add Movie',
                tooltip: 'Close',
                onClose: () => context.pop(),
                onBuild: (duringLayout) {
                  discoverBuiltDuringLayout = duringLayout;
                },
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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(moviesBuiltDuringLayout, isFalse);

    router.push('/discover');
    await tester.pumpAndSettle();
    expect(discoverBuiltDuringLayout, isFalse);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(moviesBuiltDuringLayout, isFalse);
    expect(find.text('Movies'), findsWidgets);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });
}

/// Records whether a page was built while a render object was inside a layout
/// callback. Tooltips attach an overlay layout builder, which is illegal while
/// the shell is performing layout.
class _LayoutPhaseProbe extends StatelessWidget {
  const _LayoutPhaseProbe({
    required this.label,
    required this.tooltip,
    required this.onBuild,
    this.onClose,
  });

  final String label;
  final String tooltip;
  final ValueChanged<bool> onBuild;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    onBuild(RenderObject.debugActiveLayout != null);
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            tooltip: tooltip,
            onPressed: onClose,
            icon: Icon(
              onClose == null ? Icons.notifications_outlined : Icons.close,
            ),
          ),
        ],
      ),
    );
  }
}
