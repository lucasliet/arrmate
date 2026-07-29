import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/core/services/logger_service.dart';
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

    test(
      'should not promote a fallback that returns a non-connection error',
      () async {
        final adapter = _RecordingAdapter(
          unavailableHosts: {'primary.test'},
          statusCodes: {'alternative.test': 500},
        );
        final client = _client(adapter);

        await expectLater(
          client.get<Map<String, dynamic>>('/status'),
          throwsA(isA<ServerError>()),
        );

        expect(adapter.requests.map((uri) => uri.host), [
          'primary.test',
          'alternative.test',
        ]);
      },
    );

    test('should persist only sanitized connection errors', () async {
      // Given
      logger.clearLogs();
      final adapter = _RecordingAdapter(
        unavailableHosts: {'primary.test', 'alternative.test'},
        failureReason: "Failed host lookup: 'private.home.arpa'",
      );
      final client = _client(adapter);

      // When
      await expectLater(
        client.get<Map<String, dynamic>>('/status'),
        throwsA(isA<ConnectionError>()),
      );

      // Then
      final errorEntries = logger.logs.where(
        (entry) => entry.message.startsWith('[API] Error:'),
      );
      expect(errorEntries, isNotEmpty);
      for (final entry in errorEntries) {
        expect(entry.error, isA<String>());
        expect(entry.toLogString(), isNot(contains('private.home.arpa')));
      }
    });

    test('should mask values from arbitrary custom headers', () async {
      // Given
      logger.clearLogs();
      final client = _client(
        _RecordingAdapter(),
        headers: const {
          'X-Auth': 'private-auth-value',
          'CF-Access-Client-Id': 'private-client-id',
        },
      );

      // When
      await client.get<Map<String, dynamic>>('/status');

      // Then
      final requestLog = logger.logs
          .firstWhere((entry) => entry.message.startsWith('[API] Request:'))
          .toLogString();
      expect(requestLog, contains('X-Auth'));
      expect(requestLog, contains('CF-Access-Client-Id'));
      expect(requestLog, isNot(contains('private-auth-value')));
      expect(requestLog, isNot(contains('private-client-id')));
    });
  });
}

ApiClient _client(
  _RecordingAdapter adapter, {
  Map<String, String> headers = const {'X-Api-Key': 'key'},
}) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://primary.test/api/v3',
    fallbackBaseUrls: const ['https://alternative.test/api/v3'],
    headers: headers,
    dio: dio,
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  final Set<String> unavailableHosts;
  final Map<String, int> statusCodes;
  final String failureReason;
  final List<Uri> requests = [];

  _RecordingAdapter({
    this.unavailableHosts = const {},
    this.statusCodes = const {},
    this.failureReason = 'unreachable',
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
        reason: failureReason,
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
