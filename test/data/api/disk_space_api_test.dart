import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Disk space API', () {
    test('should fetch and parse Radarr disk space', () async {
      // Given
      final adapter = _DiskSpaceAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));

      // When
      final result = await api.getDiskSpace();

      // Then
      expect(adapter.request?.path, '/api/v3/diskspace');
      expect(result, [
        const InstanceDiskSpace(
          path: '/media',
          label: 'Media',
          freeSpace: 400,
          totalSpace: 1000,
        ),
      ]);
    });

    test('should fetch and parse Sonarr disk space', () async {
      // Given
      final adapter = _DiskSpaceAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));

      // When
      final result = await api.getDiskSpace();

      // Then
      expect(adapter.request?.path, '/api/v3/diskspace');
      expect(result.single.usedSpace, 600);
    });
  });
}

Instance _instance(InstanceType type) {
  return Instance(
    id: type.name,
    type: type,
    label: type.label,
    url: 'https://${type.name}.example.com',
    apiKey: 'key',
  );
}

ApiClient _client(_DiskSpaceAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://arr.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

class _DiskSpaceAdapter implements HttpClientAdapter {
  Uri? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options.uri;
    return ResponseBody.fromString(
      jsonEncode([
        {
          'path': '/media',
          'label': 'Media',
          'freeSpace': 400,
          'totalSpace': 1000,
        },
      ]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
