import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/services/google_auth.dart';
import 'package:arrmate/core/services/google_drive_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleDriveService findBackupFile', () {
    test('shouldReturnNull_whenNoBackupExists', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({'files': []}),
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));

      // When
      final info = await service.findBackupFile();

      // Then
      expect(info, isNull);
      expect(adapter.requests.single.path, '/drive/v3/files');
      expect(
        adapter.requests.single.queryParameters['spaces'],
        'appDataFolder',
      );
      expect(
        adapter.requests.single.queryParameters['q'],
        "name = 'arrmate-backup.json'",
      );
      expect(adapter.authHeaders.single, 'Bearer token-a');
    });

    test('shouldFindExistingBackup', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({
            'files': [
              {'id': 'file-id-1', 'modifiedTime': '2026-01-02T03:04:05Z'},
            ],
          }),
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));

      // When
      final info = await service.findBackupFile();

      // Then
      expect(info, isNotNull);
      expect(info!.id, 'file-id-1');
      expect(info.modifiedTime, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });
  });

  group('GoogleDriveService uploadBackup', () {
    test('shouldCreateBackup_whenNoneExists', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({'files': []}),
          '/upload/drive/v3/files': jsonEncode({
            'id': 'new-file-id',
            'modifiedTime': '2026-02-03T04:05:06Z',
          }),
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));
      const content = '{"settings":{"theme":"dark"}}';

      // When
      final info = await service.uploadBackup(content);

      // Then
      expect(info.id, 'new-file-id');
      expect(info.modifiedTime, DateTime.utc(2026, 2, 3, 4, 5, 6));
      expect(adapter.methods, ['GET', 'POST']);
      expect(adapter.requests.last.path, '/upload/drive/v3/files');
      expect(adapter.requests.last.queryParameters['uploadType'], 'multipart');
      final body = adapter.bodies.last;
      expect(body, contains('appDataFolder'));
      expect(body, contains(GoogleDriveService.backupFileName));
      expect(body, contains(content));
      expect(
        body.indexOf('name="metadata"'),
        lessThan(body.indexOf('name="file"')),
      );
    });

    test('shouldUpdateExistingBackup', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({
            'files': [
              {'id': 'file-id-1', 'modifiedTime': '2026-01-02T03:04:05Z'},
            ],
          }),
          '/upload/drive/v3/files/file-id-1': jsonEncode({
            'id': 'file-id-1',
            'modifiedTime': '2026-03-04T05:06:07Z',
          }),
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));
      const content = '{"settings":{"updated":true}}';

      // When
      final info = await service.uploadBackup(content);

      // Then
      expect(info.id, 'file-id-1');
      expect(info.modifiedTime, DateTime.utc(2026, 3, 4, 5, 6, 7));
      expect(adapter.methods, ['GET', 'PATCH']);
      expect(adapter.requests.last.path, '/upload/drive/v3/files/file-id-1');
      expect(adapter.requests.last.queryParameters['uploadType'], 'media');
      expect(adapter.bodies.last, content);
    });
  });

  group('GoogleDriveService downloadBackup', () {
    test('shouldDownloadBackupContent', () async {
      // Given
      const content = '{"settings":{"backup":true}}';
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({
            'files': [
              {'id': 'file-id-1', 'modifiedTime': '2026-01-02T03:04:05Z'},
            ],
          }),
          '/drive/v3/files/file-id-1': content,
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));

      // When
      final downloaded = await service.downloadBackup();

      // Then
      expect(downloaded, content);
      expect(adapter.methods, ['GET', 'GET']);
      expect(adapter.requests.last.path, '/drive/v3/files/file-id-1');
      expect(adapter.requests.last.queryParameters['alt'], 'media');
    });

    test('shouldThrowNotFound_whenDownloadingWithoutBackup', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/drive/v3/files': jsonEncode({'files': []}),
        },
      );
      final service = _service(adapter, _FakeTokenProvider('token-a'));

      // When
      final result = service.downloadBackup();

      // Then
      await expectLater(result, throwsA(isA<DriveBackupNotFoundException>()));
      expect(adapter.methods, ['GET']);
    });
  });

  group('GoogleDriveService authorization retry', () {
    test('shouldRefreshAndRetryOnce_onUnauthorized', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathStatuses: {
          '/drive/v3/files': [401],
        },
        pathBodies: {
          '/drive/v3/files': jsonEncode({
            'files': [
              {'id': 'file-id-1', 'modifiedTime': '2026-01-02T03:04:05Z'},
            ],
          }),
        },
      );
      final provider = _FakeTokenProvider('token-a')
        ..refreshedToken = 'token-b';
      final service = _service(adapter, provider);

      // When
      final info = await service.findBackupFile();

      // Then
      expect(info!.id, 'file-id-1');
      expect(provider.refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
      expect(adapter.authHeaders, ['Bearer token-a', 'Bearer token-b']);
    });

    test('shouldThrowAuth_whenRetryStillUnauthorized', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathStatuses: {
          '/drive/v3/files': [401, 401],
        },
        pathBodies: {
          '/drive/v3/files': jsonEncode({'error': 'unauthorized'}),
        },
      );
      final provider = _FakeTokenProvider('token-a')
        ..refreshedToken = 'token-b';
      final service = _service(adapter, provider);

      // When
      final result = service.findBackupFile();

      // Then
      await expectLater(result, throwsA(isA<DriveAuthException>()));
      expect(provider.refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
    });
  });
}

GoogleDriveService _service(
  _RecordingAdapter adapter,
  _FakeTokenProvider provider,
) {
  final dio = Dio()..httpClientAdapter = adapter;
  return GoogleDriveService(tokenProvider: provider, dio: dio);
}

class _FakeTokenProvider implements GoogleAccessTokenProvider {
  String? token;
  String? refreshedToken;
  int refreshCalls = 0;

  _FakeTokenProvider(this.token);

  @override
  Future<String?> getValidAccessToken() async => token;

  @override
  Future<String?> refreshAccessToken() async {
    refreshCalls++;
    if (refreshedToken != null) {
      token = refreshedToken;
    }
    return refreshedToken ?? token;
  }
}

class _RecordingAdapter implements HttpClientAdapter {
  final Map<String, String> pathBodies;
  final Map<String, List<int>> pathStatuses;
  final List<Uri> requests = [];
  final List<String> methods = [];
  final List<String> authHeaders = [];
  final List<String> bodies = [];
  final Map<String, int> _callsByPath = {};

  _RecordingAdapter({
    Map<String, String>? pathBodies,
    Map<String, List<int>>? pathStatuses,
  }) : pathBodies = pathBodies ?? {},
       pathStatuses = pathStatuses ?? {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    methods.add(options.method);
    authHeaders.add(options.headers['Authorization'] as String? ?? '');
    bodies.add(await _readBody(requestStream));

    final attempt = _callsByPath.update(
      uri.path,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final statuses = pathStatuses[uri.path];
    final statusCode = statuses != null && attempt <= statuses.length
        ? statuses[attempt - 1]
        : 200;
    final body = pathBodies[uri.path] ?? jsonEncode({'ok': true});

    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Future<String> _readBody(Stream<Uint8List>? requestStream) async {
    if (requestStream == null) return '';
    final chunks = await requestStream.toList();
    return utf8.decode(chunks.expand((chunk) => chunk).toList());
  }

  @override
  void close({bool force = false}) {}
}
