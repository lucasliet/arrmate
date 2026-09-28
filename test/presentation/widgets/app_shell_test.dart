import 'package:arrmate/presentation/providers/network_status_provider.dart';
import 'package:arrmate/presentation/widgets/app_shell.dart';
import 'package:flutter/foundation.dart';
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
    expect(find.byTooltip('Search (Ctrl/Cmd+K)'), findsNothing);
  });
}
