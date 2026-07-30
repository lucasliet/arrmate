import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/network/request_diagnostics.dart';
import 'package:arrmate/core/services/system_diagnostics_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemDiagnosticsService', () {
    test(
      'should test the primary and alternative URLs independently',
      () async {
        final testedUrls = <String>[];
        final testedConnectionUrls = <List<String>>[];
        final service = SystemDiagnosticsService(
          loadConnectivity: () async => [ConnectivityResult.wifi],
          loadStatus: (instance) async {
            testedUrls.add(instance.effectiveUrl);
            testedConnectionUrls.add(instance.connectionUrls);
            if (instance.effectiveUrl.contains('remote')) {
              throw const ConnectionError();
            }
            return const InstanceStatus(
              appName: 'Radarr',
              instanceName: 'Home',
              version: '5.0.0',
            );
          },
          clock: () => DateTime.utc(2026, 7, 29),
        );

        final snapshot = await service.run([
          Instance(
            id: 'radarr-1',
            type: InstanceType.radarr,
            label: 'Home',
            url: 'http://local.test:7878',
            alternativeUrl: 'https://remote.test',
            apiKey: 'secret',
          ),
        ]);

        expect(testedUrls, ['http://local.test:7878', 'https://remote.test']);
        expect(testedConnectionUrls, [
          ['http://local.test:7878'],
          ['https://remote.test'],
        ]);
        expect(snapshot.checks, hasLength(2));
        expect(snapshot.checks.first.isSuccessful, isTrue);
        expect(snapshot.checks.last.isSuccessful, isFalse);
        expect(snapshot.checks.first.endpointLabel, 'Primary · Active');
        expect(snapshot.checks.last.endpointLabel, 'Alternative');
        expect(
          snapshot.checks.last.error,
          'Connection failed. Please check your network.',
        );
        expect(snapshot.isOffline, isFalse);
      },
    );

    test(
      'should keep the network available when every endpoint fails',
      () async {
        final service = SystemDiagnosticsService(
          loadConnectivity: () async => [ConnectivityResult.wifi],
          loadStatus: (_) async => throw const TimeoutError(),
        );

        final snapshot = await service.run([
          Instance(
            id: 'sonarr-1',
            type: InstanceType.sonarr,
            label: 'TV',
            url: 'https://sonarr.test',
            apiKey: 'secret',
          ),
        ]);

        expect(snapshot.hasNetworkInterface, isTrue);
        expect(snapshot.isOffline, isFalse);
        expect(snapshot.areAllEndpointsUnavailable, isTrue);
      },
    );

    test(
      'should mark the device offline only without a network interface',
      () async {
        final service = SystemDiagnosticsService(
          loadConnectivity: () async => [ConnectivityResult.none],
          loadStatus: (_) async => throw const TimeoutError(),
        );

        final snapshot = await service.run(const []);

        expect(snapshot.hasNetworkInterface, isFalse);
        expect(snapshot.isOffline, isTrue);
        expect(snapshot.areAllEndpointsUnavailable, isFalse);
      },
    );
  });

  group('DiagnosticReportBuilder', () {
    test('should redact credentials, hosts, queries, and request bodies', () {
      final builder = DiagnosticReportBuilder();
      final snapshot = SystemDiagnosticsSnapshot(
        generatedAt: DateTime.utc(2026, 7, 29),
        networkInterfaces: const ['wifi'],
        checks: const [
          InstanceDiagnosticCheck(
            instanceId: 'private-id',
            instanceLabel: 'Private label',
            instanceType: InstanceType.radarr,
            endpointLabel: 'Active',
            endpoint:
                'https://user:password@private.example:7878/base?token=secret',
            isSuccessful: true,
            duration: Duration(milliseconds: 42),
            version: '5.0.0',
          ),
        ],
      );

      final report = builder.build(
        snapshot: snapshot,
        requests: [
          RequestDiagnosticEntry(
            source: 'private-id',
            method: 'GET',
            path: '/api/v3/movie',
            statusCode: 200,
            startedAt: DateTime.utc(2026, 7, 29),
            duration: const Duration(milliseconds: 12),
          ),
        ],
        appVersion: '1.0.0',
        buildNumber: '1',
        platform: 'Android authorization=Bearer-secret',
      );

      expect(report, contains('Instance 1'));
      expect(report, contains('https://<redacted-host>:7878/base'));
      expect(report, isNot(contains('private.example')));
      expect(report, isNot(contains('Private label')));
      expect(report, isNot(contains('secret')));
      expect(report, isNot(contains('private-id')));
      expect(report, isNot(contains('Recent app logs')));
      expect(report, contains('Network available: true'));
      expect(report, contains('All endpoints unavailable: false'));
    });
  });
}
