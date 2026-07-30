import 'package:arrmate/core/network/instance_connection_resolver.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstanceConnectionResolver', () {
    test('should prefer the primary URL on a local network', () async {
      final probes = <Uri>[];
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        ping: (instance, uri) async {
          probes.add(uri);
          return true;
        },
      );

      final resolved = await resolver.resolve(_instance());

      expect(resolved.effectiveUrl, 'http://192.168.1.10:7878');
      expect(probes.single.path, '/ping');
    });

    test('should prefer the alternative URL on a mobile network', () async {
      final probes = <Uri>[];
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.mobile],
        ping: (instance, uri) async {
          probes.add(uri);
          return true;
        },
      );

      final resolved = await resolver.resolve(_instance());

      expect(resolved.effectiveUrl, 'https://radarr.example.com');
      expect(probes.single.host, 'radarr.example.com');
    });

    test('should fail over when the preferred URL does not respond', () async {
      final probes = <Uri>[];
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        ping: (instance, uri) async {
          probes.add(uri);
          return uri.host == 'radarr.example.com';
        },
      );

      final resolved = await resolver.resolve(_instance());

      expect(resolved.effectiveUrl, 'https://radarr.example.com');
      expect(probes.map((uri) => uri.host), [
        '192.168.1.10',
        'radarr.example.com',
      ]);
    });

    test(
      'should keep the network preference when probes are inconclusive',
      () async {
        final resolver = InstanceConnectionResolver(
          loadConnectivity: () async => [ConnectivityResult.wifi],
          ping: (instance, uri) async => false,
        );

        final resolved = await resolver.resolve(_instance());

        expect(resolved.effectiveUrl, 'http://192.168.1.10:7878');
      },
    );

    test('should append ping to an existing base path', () async {
      Uri? probedUri;
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        ping: (instance, uri) async {
          probedUri = uri;
          return true;
        },
      );
      final instance = _instance().copyWith(
        url: 'https://local.example.com/radarr/',
      );

      await resolver.resolve(instance);

      expect(probedUri?.path, '/radarr/ping');
    });

    test('should not send inline credentials in a ping probe', () async {
      Uri? probedUri;
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        ping: (instance, uri) async {
          probedUri = uri;
          return true;
        },
      );
      final instance = _instance().copyWith(
        url: 'https://user:password@local.example.com/radarr',
      );

      await resolver.resolve(instance);

      expect(probedUri?.userInfo, isEmpty);
      expect(probedUri?.host, 'local.example.com');
    });

    test('should probe the qBittorrent version endpoint for a qBittorrent '
        'instance', () async {
      Uri? probedUri;
      InstanceType? probedType;
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        ping: (instance, uri) async {
          probedUri = uri;
          probedType = instance.type;
          return true;
        },
      );

      final resolved = await resolver.resolve(_qbitInstance());

      expect(resolved.effectiveUrl, 'http://192.168.1.10:8080');
      expect(probedType, InstanceType.qbittorrent);
      expect(probedUri?.path, '/api/v2/app/version');
    });
  });
}

Instance _instance() {
  return Instance(
    id: 'radarr',
    type: InstanceType.radarr,
    label: 'Radarr',
    url: 'http://192.168.1.10:7878',
    alternativeUrl: 'https://radarr.example.com',
    apiKey: 'key',
  );
}

Instance _qbitInstance() {
  return Instance(
    id: 'qbit',
    type: InstanceType.qbittorrent,
    label: 'qBittorrent',
    url: 'http://192.168.1.10:8080',
    alternativeUrl: 'https://qbit.example.com',
    apiKey: 'user:pass',
  );
}
