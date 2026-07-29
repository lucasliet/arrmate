import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/core/network/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient failover', () {
    test('should retry a connection failure on the alternative URL', () async {
      final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
      final client = _client(adapter);

      final response = await client.get<Map<String, dynamic>>('/status');

      expect(response['host'], 'alternative.test');
      expect(adapter.requests.map((uri) => uri.host), [
        'primary.test',
        'alternative.test',
      ]);
      expect(adapter.requests.last.path, '/api/v3/status');
    });

    test('should keep using the successful alternative URL', () async {
      final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
      final client = _client(adapter);

      await client.get<Map<String, dynamic>>('/status');
      await client.get<Map<String, dynamic>>('/health');

      expect(adapter.requests.map((uri) => uri.host), [
        'primary.test',
        'alternative.test',
        'alternative.test',
      ]);
    });

    test('should not retry an HTTP authentication failure', () async {
      final adapter = _RecordingAdapter(statusCodes: {'primary.test': 401});
      final client = _client(adapter);

      await expectLater(
        client.get<Map<String, dynamic>>('/status'),
        throwsA(isA<UnauthorizedError>()),
      );

      expect(adapter.requests.map((uri) => uri.host), ['primary.test']);
    });

    test(
      'should not retry a mutating request after a connection error',
      () async {
        final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
        final client = _client(adapter);

        await expectLater(
          client.post<Map<String, dynamic>>(
            '/command',
            data: {'name': 'Search'},
          ),
          throwsA(isA<ConnectionError>()),
        );

        expect(adapter.requests.map((uri) => uri.host), ['primary.test']);
      },
    );
  });
}

ApiClient _client(_RecordingAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://primary.test/api/v3',
    fallbackBaseUrls: const ['https://alternative.test/api/v3'],
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  final Set<String> unavailableHosts;
  final Map<String, int> statusCodes;
  final List<Uri> requests = [];

  _RecordingAdapter({
    this.unavailableHosts = const {},
    this.statusCodes = const {},
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    if (unavailableHosts.contains(uri.host)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'host': uri.host}),
      statusCodes[uri.host] ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
