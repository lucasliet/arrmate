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

  group('Health check command', () {
    // Radarr and Sonarr register the command as `CheckHealth`; any other name
    // makes `POST /command` answer 500 ("Sequence contains no matching
    // element") and the health screen reports that the check could not start.
    test('should ask Radarr to run the CheckHealth command', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = RadarrApi(
        _instance(InstanceType.radarr),
        _client(adapter, 'radarr'),
      );

      // When
      await api.healthCheck();

      // Then
      expect(adapter.path, '/api/v3/command');
      expect(adapter.body, {'name': 'CheckHealth'});
    });

    test('should ask Sonarr to run the CheckHealth command', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = SonarrApi(
        _instance(InstanceType.sonarr),
        _client(adapter, 'sonarr'),
      );

      // When
      await api.healthCheck();

      // Then
      expect(adapter.path, '/api/v3/command');
      expect(adapter.body, {'name': 'CheckHealth'});
    });
  });
}

Instance _instance(InstanceType type) {
  return Instance(
    id: type.name,
    type: type,
    label: type.name,
    url: 'https://${type.name}.example.com',
    apiKey: 'key',
  );
}

ApiClient _client(_CommandAdapter adapter, String host) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://$host.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

/// Records the command posted to the server and answers it as accepted.
class _CommandAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    body = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode({'id': 1, 'name': body!['name']}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
