import 'dart:async';

import 'package:arrmate/core/network/request_diagnostics.dart';
import 'package:arrmate/core/services/system_diagnostics_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/settings/diagnostics_screen.dart';
import 'package:arrmate/presentation/screens/settings/system_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _instancesStateProvider =
    NotifierProvider<_InstancesStateController, InstancesState>(
      _InstancesStateController.new,
    );

class _InstancesStateController extends Notifier<InstancesState> {
  @override
  InstancesState build() => const InstancesState();

  void replace(InstancesState next) {
    state = next;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RequestDiagnosticsRecorder.instance.clear();
  });

  tearDown(RequestDiagnosticsRecorder.instance.clear);

  test(
    'should complete the initial diagnostics future after instances load',
    () async {
      // Given
      final snapshot = _snapshot(checks: _checks());
      final container = ProviderContainer(
        overrides: [
          diagnosticsInstancesStateProvider.overrideWith((ref) {
            return ref.watch(_instancesStateProvider);
          }),
          systemDiagnosticsRunnerProvider.overrideWithValue(
            (_) async => snapshot,
          ),
        ],
      );
      addTearDown(container.dispose);

      // When
      final initialFuture = container.read(systemDiagnosticsProvider.future);
      container
          .read(_instancesStateProvider.notifier)
          .replace(
            InstancesState(instances: _configuredInstances(), isLoading: false),
          );

      // Then
      expect(await initialFuture, snapshot);
    },
  );

  testWidgets(
    'should wait for configured instances and run all supported types',
    (tester) async {
      // Given
      final runCompleter = Completer<SystemDiagnosticsSnapshot>();
      List<Instance>? receivedInstances;
      final container = ProviderContainer(
        overrides: [
          diagnosticsInstancesStateProvider.overrideWith((ref) {
            return ref.watch(_instancesStateProvider);
          }),
          systemDiagnosticsRunnerProvider.overrideWithValue((instances) {
            receivedInstances = instances;
            return runCompleter.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      // When
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DiagnosticsScreen()),
        ),
      );

      // Then
      expect(find.text('Checking configured endpoints...'), findsOneWidget);
      expect(receivedInstances, isNull);

      // When
      container
          .read(_instancesStateProvider.notifier)
          .replace(
            InstancesState(instances: _configuredInstances(), isLoading: false),
          );
      await tester.pump();

      // Then
      expect(
        receivedInstances?.map((instance) => instance.type),
        containsAll(InstanceType.values),
      );
      expect(find.text('Checking configured endpoints...'), findsOneWidget);

      // When
      runCompleter.complete(_snapshot(checks: _checks()));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Connection Diagnostics'), findsOneWidget);
      expect(find.text('Connection troubleshooting'), findsOneWidget);
      expect(
        find.textContaining(
          'Health shows alerts reported by Radarr and Sonarr',
        ),
        findsOneWidget,
      );
      expect(find.text('Endpoint connectivity'), findsOneWidget);
      expect(find.text('Home Radarr · Primary endpoint'), findsOneWidget);
      expect(find.text('TV Sonarr · Active endpoint'), findsOneWidget);
      expect(find.text('Downloads · Alternative endpoint'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Recent request traces'),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      expect(find.text('Recent request traces'), findsOneWidget);
    },
  );

  testWidgets(
    'should separate an available network from unavailable endpoints',
    (tester) async {
      // Given
      final snapshot = _snapshot(checks: [_checks().last]);
      final container = ProviderContainer(
        overrides: [
          diagnosticsInstancesStateProvider.overrideWithValue(
            InstancesState(instances: _configuredInstances(), isLoading: false),
          ),
          systemDiagnosticsRunnerProvider.overrideWithValue(
            (_) async => snapshot,
          ),
        ],
      );
      addTearDown(container.dispose);

      // When
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DiagnosticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Network available'), findsOneWidget);
      expect(find.text('Endpoints unavailable'), findsOneWidget);
      expect(find.text('No network interface'), findsNothing);
    },
  );

  testWidgets('should keep previous results visible while refreshing', (
    tester,
  ) async {
    // Given
    final refreshCompleter = Completer<SystemDiagnosticsSnapshot>();
    var runCount = 0;
    final previousSnapshot = _snapshot(
      checks: [_checks().first],
      generatedAt: DateTime(2026, 7, 28),
    );
    final container = ProviderContainer(
      overrides: [
        diagnosticsInstancesStateProvider.overrideWithValue(
          InstancesState(instances: _configuredInstances(), isLoading: false),
        ),
        systemDiagnosticsRunnerProvider.overrideWithValue((_) {
          runCount++;
          if (runCount == 1) {
            return Future.value(previousSnapshot);
          }
          return refreshCompleter.future;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiagnosticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // When
    await tester.tap(find.byTooltip('Run connection checks again'));
    await tester.pump();

    // Then
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Refreshing endpoint checks...'), findsOneWidget);
    expect(find.text('Home Radarr · Primary endpoint'), findsOneWidget);

    // When
    refreshCompleter.complete(
      _snapshot(checks: [_checks()[1]], generatedAt: DateTime(2026, 7, 29)),
    );
    await tester.pumpAndSettle();

    // Then
    expect(find.text('Refreshing endpoint checks...'), findsNothing);
    expect(find.text('TV Sonarr · Active endpoint'), findsOneWidget);
  });

  testWidgets(
    'should ignore an old refresh after configured instances change',
    (tester) async {
      // Given
      final staleRefreshCompleter = Completer<SystemDiagnosticsSnapshot>();
      final firstInstance = _configuredInstances().first;
      final secondInstance = _configuredInstances()[1];
      var firstInstanceRuns = 0;
      final firstSnapshot = _snapshot(checks: [_checks().first]);
      final secondSnapshot = _snapshot(checks: [_checks()[1]]);
      final container = ProviderContainer(
        overrides: [
          diagnosticsInstancesStateProvider.overrideWith((ref) {
            return ref.watch(_instancesStateProvider);
          }),
          systemDiagnosticsRunnerProvider.overrideWithValue((instances) {
            if (instances.single.id == secondInstance.id) {
              return Future.value(secondSnapshot);
            }
            firstInstanceRuns++;
            if (firstInstanceRuns == 1) {
              return Future.value(firstSnapshot);
            }
            return staleRefreshCompleter.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(_instancesStateProvider.notifier)
          .replace(
            InstancesState(instances: [firstInstance], isLoading: false),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DiagnosticsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Run connection checks again'));
      await tester.pump();

      // When
      container
          .read(_instancesStateProvider.notifier)
          .replace(
            InstancesState(instances: [secondInstance], isLoading: false),
          );
      await tester.pump();
      await tester.pump();

      // Then
      expect(find.text('TV Sonarr · Active endpoint'), findsOneWidget);

      // When
      staleRefreshCompleter.complete(firstSnapshot);
      await tester.pumpAndSettle();

      // Then
      expect(find.text('TV Sonarr · Active endpoint'), findsOneWidget);
      expect(find.text('Home Radarr · Primary endpoint'), findsNothing);
    },
  );

  testWidgets('should export sanitized request diagnostics without app logs', (
    tester,
  ) async {
    // Given
    String? exportedReport;
    final snapshot = _snapshot(
      checks: [
        InstanceDiagnosticCheck(
          instanceId: 'radarr',
          instanceLabel: 'Private Radarr',
          instanceType: InstanceType.radarr,
          endpointLabel: 'Primary',
          endpoint:
              'https://user:password@radarr.example.com/api?apikey=secret',
          isSuccessful: true,
          duration: const Duration(milliseconds: 20),
          version: '5.0.0',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        diagnosticsInstancesStateProvider.overrideWithValue(
          InstancesState(instances: _configuredInstances(), isLoading: false),
        ),
        systemDiagnosticsRunnerProvider.overrideWithValue(
          (_) async => snapshot,
        ),
        diagnosticsPackageInfoLoaderProvider.overrideWithValue(
          () async => PackageInfo(
            appName: 'Arrmate',
            packageName: 'br.com.lucasliet.arrmate',
            version: '1.2.3',
            buildNumber: '45',
          ),
        ),
        diagnosticReportExporterProvider.overrideWithValue((report) async {
          exportedReport = report;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiagnosticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // When
    await tester.tap(find.byTooltip('Export report'));
    await tester.pumpAndSettle();

    // Then
    expect(exportedReport, contains('App: 1.2.3+45'));
    expect(exportedReport, isNot(contains('Recent app logs')));
    expect(exportedReport, isNot(contains('radarr.example.com')));
    expect(exportedReport, isNot(contains('password')));
    expect(exportedReport, isNot(contains('secret')));
  });

  testWidgets('should distinguish Health from Connection Diagnostics', (
    tester,
  ) async {
    // Given
    PackageInfo.setMockInitialValues(
      appName: 'Arrmate',
      packageName: 'br.com.lucasliet.arrmate',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // When
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SystemManagementScreen())),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Connection Diagnostics'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );

    // Then
    expect(find.text('Health'), findsOneWidget);
    expect(
      find.text('Server-reported Radarr and Sonarr alerts'),
      findsOneWidget,
    );
    expect(find.text('Connection Diagnostics'), findsOneWidget);
    expect(
      find.text('Test endpoints, latency, request traces, and export a report'),
      findsOneWidget,
    );
    final healthTop = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Health'))
        .dy;
    final diagnosticsTop = tester
        .getTopLeft(find.widgetWithText(ListTile, 'Connection Diagnostics'))
        .dy;
    expect(healthTop, lessThan(diagnosticsTop));
  });
}

List<Instance> _configuredInstances() {
  return [
    Instance(
      id: 'radarr',
      type: InstanceType.radarr,
      label: 'Home Radarr',
      url: 'https://radarr.example.com',
      apiKey: 'key',
    ),
    Instance(
      id: 'sonarr',
      type: InstanceType.sonarr,
      label: 'TV Sonarr',
      url: 'https://sonarr.example.com',
      apiKey: 'key',
    ),
    Instance(
      id: 'qbittorrent',
      type: InstanceType.qbittorrent,
      label: 'Downloads',
      url: 'https://downloads.example.com',
      apiKey: 'key',
    ),
  ];
}

List<InstanceDiagnosticCheck> _checks() {
  return [
    const InstanceDiagnosticCheck(
      instanceId: 'radarr',
      instanceLabel: 'Home Radarr',
      instanceType: InstanceType.radarr,
      endpointLabel: 'Primary',
      endpoint: 'https://radarr.example.com',
      isSuccessful: true,
      duration: Duration(milliseconds: 10),
      version: '5.0.0',
    ),
    const InstanceDiagnosticCheck(
      instanceId: 'sonarr',
      instanceLabel: 'TV Sonarr',
      instanceType: InstanceType.sonarr,
      endpointLabel: 'Active',
      endpoint: 'https://sonarr.example.com',
      isSuccessful: true,
      duration: Duration(milliseconds: 12),
      version: '4.0.0',
    ),
    const InstanceDiagnosticCheck(
      instanceId: 'qbittorrent',
      instanceLabel: 'Downloads',
      instanceType: InstanceType.qbittorrent,
      endpointLabel: 'Alternative',
      endpoint: 'https://downloads.example.com',
      isSuccessful: false,
      duration: Duration(milliseconds: 15),
      error: 'connection timeout',
    ),
  ];
}

SystemDiagnosticsSnapshot _snapshot({
  required List<InstanceDiagnosticCheck> checks,
  DateTime? generatedAt,
}) {
  return SystemDiagnosticsSnapshot(
    generatedAt: generatedAt ?? DateTime(2026, 7, 29),
    networkInterfaces: const ['wifi'],
    checks: checks,
  );
}
