import 'dart:typed_data';

import 'package:arrmate/core/network/request_diagnostics.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestDiagnosticsInterceptor', () {
    test('should record sanitized response metadata', () async {
      final recorder = RequestDiagnosticsRecorder();
      final dio = Dio();
      dio.httpClientAdapter = _DiagnosticAdapter();
      dio.interceptors.add(
        RequestDiagnosticsInterceptor(source: 'instance-1', recorder: recorder),
      );

      await dio.get<dynamic>(
        'https://example.test/api/v3/movie',
        queryParameters: {'apikey': 'secret'},
      );

      expect(recorder.entries, hasLength(1));
      final entry = recorder.entries.single;
      expect(entry.source, 'instance-1');
      expect(entry.method, 'GET');
      expect(entry.path, '/api/v3/movie');
      expect(entry.statusCode, 200);
      expect(entry.isSuccessful, isTrue);
      expect(entry.path, isNot(contains('secret')));
    });

    test('should retain only the newest one hundred entries', () {
      final recorder = RequestDiagnosticsRecorder();

      for (var index = 0; index < 105; index++) {
        recorder.record(
          RequestDiagnosticEntry(
            source: 'instance',
            method: 'GET',
            path: '/request/$index',
            statusCode: 200,
            startedAt: DateTime(2026),
            duration: Duration.zero,
          ),
        );
      }

      expect(recorder.entries, hasLength(100));
      expect(recorder.entries.first.path, '/request/104');
      expect(recorder.entries.last.path, '/request/5');
    });
  });
}

class _DiagnosticAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}
