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

  group('Calendar API', () {
    test('should request unmonitored movies from Radarr', () async {
      // Given
      final adapter = _CalendarAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));
      final start = DateTime.utc(2026, 7, 1);
      final end = DateTime.utc(2026, 8, 15);

      // When
      await api.getCalendar(start: start, end: end);

      // Then
      expect(adapter.request?.path, '/api/v3/calendar');
      expect(adapter.request?.queryParameters, {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'unmonitored': 'true',
      });
    });

    test(
      'should request unmonitored episodes and series from Sonarr',
      () async {
        // Given
        final adapter = _CalendarAdapter();
        final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));
        final start = DateTime.utc(2026, 7, 1);
        final end = DateTime.utc(2026, 8, 15);

        // When
        await api.getCalendar(start: start, end: end);

        // Then
        expect(adapter.request?.path, '/api/v3/calendar');
        expect(adapter.request?.queryParameters, {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
          'unmonitored': 'true',
          'includeSeries': 'true',
          'includeEpisodeFile': 'true',
        });
      },
    );
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

ApiClient _client(_CalendarAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://arr.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

class _CalendarAdapter implements HttpClientAdapter {
  Uri? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options.uri;
    return ResponseBody.fromString(
      jsonEncode([]),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
