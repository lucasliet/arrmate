import 'dart:typed_data';

import 'package:arrmate/core/network/instance_connection_resolver.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstanceConnectionResolver jellyfin probe', () {
    test('probes /System/Info/Public and succeeds on HTTP 200', () async {
      // Given
      final adapter = _StaticAdapter();
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        dio: Dio()..httpClientAdapter = adapter,
      );

      // When
      final resolved = await resolver.resolve(_jellyfinInstance());

      // Then
      expect(resolved.effectiveUrl, 'http://jf-local.test:8096');
      expect(adapter.requests.single.path, '/System/Info/Public');
    });

    test('fails over when the public probe does not answer 200', () async {
      // Given
      final adapter = _StaticAdapter(
        statusByHost: {'jf-local.test': 503, 'jf-remote.test': 200},
      );
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        dio: Dio()..httpClientAdapter = adapter,
      );

      // When
      final resolved = await resolver.resolve(_jellyfinInstance());

      // Then
      expect(resolved.effectiveUrl, 'https://jf-remote.test');
      expect(
        adapter.requests.map((uri) => uri.path),
        everyElement('/System/Info/Public'),
      );
    });

    test('does not require a JSON body from the public probe', () async {
      // Given
      final adapter = _StaticAdapter(
        body: '<html>service alive</html>',
        contentType: Headers.textPlainContentType,
      );
      final resolver = InstanceConnectionResolver(
        loadConnectivity: () async => [ConnectivityResult.wifi],
        dio: Dio()..httpClientAdapter = adapter,
      );

      // When
      final resolved = await resolver.resolve(_jellyfinInstance());

      // Then
      expect(resolved.effectiveUrl, 'http://jf-local.test:8096');
    });
  });
}

Instance _jellyfinInstance() {
  return Instance(
    id: 'jf',
    type: InstanceType.jellyfin,
    label: 'Jellyfin',
    url: 'http://jf-local.test:8096',
    alternativeUrl: 'https://jf-remote.test',
    apiKey: 'key',
  );
}

/// Serves a canned system info response for every request.
class _StaticAdapter implements HttpClientAdapter {
  final Map<String, int> statusByHost;
  final String body;
  final String contentType;

  final List<Uri> requests = [];

  _StaticAdapter({
    this.statusByHost = const {},
    this.body = '{"ServerName":"Jelly","Version":"10.9.0"}',
    this.contentType = Headers.jsonContentType,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    return ResponseBody.fromString(
      body,
      statusByHost[options.uri.host] ?? 200,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
