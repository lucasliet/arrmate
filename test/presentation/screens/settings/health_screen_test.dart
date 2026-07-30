import 'dart:async';

import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/advanced_providers.dart';
import 'package:arrmate/presentation/screens/settings/health_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubHealthNotifier extends HealthNotifier {
  _StubHealthNotifier(this.overview);

  final HealthOverview overview;

  @override
  Future<HealthOverview> build() async => overview;

  @override
  Future<void> runHealthChecks() async {}
}

class _PendingHealthNotifier extends HealthNotifier {
  _PendingHealthNotifier(this.result);

  final Future<HealthOverview> result;

  @override
  Future<HealthOverview> build() => result;
}

void main() {
  testWidgets('should not show a healthy state when every source fails', (
    tester,
  ) async {
    // Given
    const overview = HealthOverview(
      configuredSourceCount: 2,
      connectionFailures: [
        HealthConnectionFailure(
          service: 'Radarr',
          operation: HealthConnectionOperation.loadStatus,
        ),
        HealthConnectionFailure(
          service: 'Sonarr',
          operation: HealthConnectionOperation.loadStatus,
        ),
      ],
    );

    // When
    await _pumpScreen(tester, overview);

    // Then
    expect(find.text('Connection issues'), findsOneWidget);
    expect(find.text('Radarr connection failed'), findsOneWidget);
    expect(find.text('Sonarr connection failed'), findsOneWidget);
    expect(find.text('No server issues found'), findsNothing);
  });

  testWidgets('should show connection failures alongside server warnings', (
    tester,
  ) async {
    // Given
    const overview = HealthOverview(
      configuredSourceCount: 2,
      serverChecks: [
        HealthCheck(
          source: 'Indexer',
          type: 'warning',
          message: 'Indexer is unavailable',
          wikiUrl: '',
        ),
      ],
      connectionFailures: [
        HealthConnectionFailure(
          service: 'Sonarr',
          operation: HealthConnectionOperation.loadStatus,
        ),
      ],
    );

    // When
    await _pumpScreen(tester, overview);

    // Then
    expect(find.text('Connection issues'), findsOneWidget);
    expect(find.text('Sonarr connection failed'), findsOneWidget);
    expect(find.text('Server warnings'), findsOneWidget);
    expect(find.text('Indexer'), findsOneWidget);
    expect(find.text('Indexer is unavailable'), findsOneWidget);
  });

  testWidgets('should only show a healthy state after a successful response', (
    tester,
  ) async {
    // Given
    const overview = HealthOverview(configuredSourceCount: 1);

    // When
    await _pumpScreen(tester, overview);

    // Then
    expect(find.text('No server issues found'), findsOneWidget);
    expect(
      find.text('Connected servers reported no health warnings.'),
      findsOneWidget,
    );
  });

  testWidgets('should distinguish missing configuration from healthy servers', (
    tester,
  ) async {
    // Given
    const overview = HealthOverview(configuredSourceCount: 0);

    // When
    await _pumpScreen(tester, overview);

    // Then
    expect(find.text('No Arr instances configured'), findsOneWidget);
    expect(find.text('No server issues found'), findsNothing);
  });

  testWidgets('should disable new checks while health is loading', (
    tester,
  ) async {
    // Given
    final result = Completer<HealthOverview>();

    // When
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith(
            () => _PendingHealthNotifier(result.future),
          ),
        ],
        child: const MaterialApp(home: HealthScreen()),
      ),
    );
    await tester.pump();

    // Then
    final buttonFinder = find.widgetWithIcon(
      IconButton,
      Icons.health_and_safety,
    );
    IconButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    result.complete(const HealthOverview(configuredSourceCount: 1));
    await tester.pumpAndSettle();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
  });
}

Future<void> _pumpScreen(WidgetTester tester, HealthOverview overview) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        healthProvider.overrideWith(() => _StubHealthNotifier(overview)),
      ],
      child: const MaterialApp(home: HealthScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
