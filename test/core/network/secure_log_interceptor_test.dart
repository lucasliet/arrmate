import 'dart:convert';

import 'package:arrmate/core/network/secure_log_interceptor.dart';
import 'package:arrmate/core/services/logger_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late _RecordingAdapter adapter;

  setUp(() {
    dio = Dio();
    dio.interceptors.add(SecureLogInterceptor());
    adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
  });

  tearDown(() => logger.clearLogs());

  group('SecureLogInterceptor onRequest', () {
    test(
      'should mask every header value while preserving header names',
      () async {
        // Given
        logger.clearLogs();

        // When
        await dio.get<dynamic>(
          'https://example.test/api/v3/movie',
          options: Options(
            headers: {
              'X-Api-Key': 'super-secret-key',
              'X-Auth': 'private-auth-value',
            },
          ),
        );

        // Then
        final log = _readLog('[API] Request:');
        expect(log, contains('X-Api-Key'));
        expect(log, contains('X-Auth'));
        expect(log, contains('***MASKED***'));
        expect(log, isNot(contains('super-secret-key')));
        expect(log, isNot(contains('private-auth-value')));
      },
    );

    test(
      'should mask sensitive query parameters case-insensitively and keep others',
      () async {
        // Given
        logger.clearLogs();

        // When
        await dio.get<dynamic>(
          'https://example.test/api/v3/movie',
          queryParameters: {
            'apikey': 'query-secret',
            'Token': 'tok',
            'page': 2,
          },
        );

        // Then
        final log = _readLog('[API] Request:');
        expect(log, contains('***MASKED***'));
        expect(log, contains('page'));
        expect(log, isNot(contains('query-secret')));
        expect(log, isNot(contains('tok')));
      },
    );

    test('should redact hosts and ips in the request path', () async {
      // Given
      logger.clearLogs();

      // When
      await dio.get<dynamic>('https://192.168.0.10:7878/api/v3/movie');

      // Then
      final log = _readLog('[API] Request:');
      expect(log, isNot(contains('192.168.0.10')));
    });

    test('should report body type none when request has no data', () async {
      // Given
      logger.clearLogs();

      // When
      await dio.get<dynamic>('https://example.test/api/v3/movie');

      // Then
      final log = _readLog('[API] Request:');
      expect(log, contains('Body type: none'));
    });

    test('should report the body runtime type for POST requests', () async {
      // Given
      logger.clearLogs();

      // When
      await dio.post<dynamic>(
        'https://example.test/api/v3/command',
        data: {'name': 'RefreshMovie'},
      );

      // Then
      final log = _readLog('[API] Request:');
      expect(log, contains('Body type:'));
      expect(log, isNot(contains('Body type: none')));
    });
  });

  group('SecureLogInterceptor onResponse', () {
    test(
      'should log status code and body type for successful responses',
      () async {
        // Given
        logger.clearLogs();

        // When
        await dio.get<dynamic>('https://example.test/api/v3/movie');

        // Then
        final log = _readLog('[API] Response:');
        expect(log, contains('200'));
        expect(log, contains('Body type:'));
      },
    );
  });

  group('SecureLogInterceptor onError', () {
    test(
      'should redact message and path and show status code for bad responses',
      () async {
        // Given
        adapter.statusCodes = {'192.168.1.5': 500};
        logger.clearLogs();

        // When
        await expectLater(
          dio.get<dynamic>('https://192.168.1.5:8989/api/v3/series'),
          throwsA(isA<DioException>()),
        );

        // Then
        final log = _readLog('[API] Error:');
        expect(log, contains('500'));
        expect(log, isNot(contains('192.168.1.5')));
      },
    );

    test(
      'should report unavailable status when the error has no response',
      () async {
        // Given
        adapter.unavailableHosts.add('example.test');
        logger.clearLogs();

        // When
        await expectLater(
          dio.get<dynamic>('https://admin:secret@example.test/api/v3/movie'),
          throwsA(isA<DioException>()),
        );

        // Then
        final log = _readLog('[API] Error:');
        expect(log, contains('unavailable'));
        expect(log, isNot(contains('admin')));
        expect(log, isNot(contains('secret')));
      },
    );
  });
}

String _readLog(String prefix) {
  final entry = logger.logs.firstWhere(
    (entry) => entry.message.startsWith(prefix),
  );
  return entry.toLogString();
}

class _RecordingAdapter implements HttpClientAdapter {
  final Set<String> unavailableHosts = {};
  Map<String, int> statusCodes = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final host = options.uri.host;
    if (unavailableHosts.contains(host)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }

    final statusCode = statusCodes[host] ?? 200;
    return ResponseBody.fromString(
      jsonEncode({'host': host}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
