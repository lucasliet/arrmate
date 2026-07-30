import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QBittorrentService failover', () {
    test(
      'should retry a GET on the alternative URL when the primary fails',
      () async {
        final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
        final service = _service(adapter);

        final torrents = await service.getTorrents();

        expect(torrents, hasLength(1));
        expect(adapter.requests.map((uri) => uri.host), [
          'primary.test',
          'alternative.test',
        ]);
      },
    );

    test(
      'should keep using the alternative URL after a successful failover',
      () async {
        final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
        final service = _service(adapter);

        await service.getTorrents();
        await service.getTorrents();

        expect(adapter.requests.map((uri) => uri.host), [
          'primary.test',
          'alternative.test',
          'alternative.test',
        ]);
      },
    );

    test('should not fail over a mutating request', () async {
      final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
      final service = _service(adapter);

      await expectLater(
        service.pauseTorrents(['hash']),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests.map((uri) => uri.host), ['primary.test']);
    });

    test(
      'should not promote a fallback that returns a non-connection error',
      () async {
        final adapter = _RecordingAdapter(
          unavailableHosts: {'primary.test'},
          statusCodes: {'alternative.test': 500},
        );
        final service = _service(adapter);

        await expectLater(service.getTorrents(), throwsA(isA<DioException>()));

        expect(adapter.requests.map((uri) => uri.host), [
          'primary.test',
          'alternative.test',
        ]);
      },
    );

    test(
      'should authenticate against the failover candidate when the primary is '
      'unreachable (cookie mode)',
      () async {
        final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
        final service = _serviceCookie(adapter);

        final torrents = await service.getTorrents();

        expect(torrents, hasLength(1));
        // Cookie mode triggers POST login before each GET. The primary is
        // unreachable so the login POST fails over to the alternative, which
        // responds with a session cookie, then the GET runs against it.
        expect(adapter.requests.map((uri) => uri.host), [
          'primary.test', // POST /api/v2/auth/login → connectionError
          'alternative.test', // POST /api/v2/auth/login → 200 + Set-Cookie
          'alternative.test', // GET /api/v2/torrents/info → 200
        ]);
        expect(adapter.methods, ['POST', 'POST', 'GET']);
      },
    );

    test('should not promote a fallback that returns 401', () async {
      final adapter = _RecordingAdapter(
        unavailableHosts: {'primary.test'},
        statusCodes: {'alternative.test': 401},
      );
      final service = _service(adapter);

      // 401 < 500 passes validateStatus, so it returns gracefully.
      final torrents = await service.getTorrents();
      expect(torrents, isEmpty);

      expect(adapter.requests.map((uri) => uri.host), [
        'primary.test',
        'alternative.test',
      ]);
      // After a 401 the active URL stays on the primary, so a second call
      // should try primary first again.
      adapter.unavailableHosts.remove('primary.test');
      adapter.statusCodes['primary.test'] = 200;
      final torrents2 = await service.getTorrents();
      expect(torrents2, hasLength(1));

      expect(adapter.requests.map((uri) => uri.host), [
        'primary.test',
        'alternative.test',
        'primary.test', // primary first again → not stuck on alternative
      ]);
    });
  });
}

QBittorrentService _service(_RecordingAdapter adapter) {
  final instance = Instance(
    id: 'qbit',
    type: InstanceType.qbittorrent,
    label: 'qBittorrent',
    url: 'https://primary.test',
    alternativeUrl: 'https://alternative.test',
    apiKey: 'bearer-token',
  );
  final dio = Dio()
    ..httpClientAdapter = adapter
    ..options.baseUrl = instance.effectiveUrl
    ..options.validateStatus = (status) => status != null && status < 500;
  return QBittorrentService(instance, dio: dio);
}

QBittorrentService _serviceCookie(_RecordingAdapter adapter) {
  final instance = Instance(
    id: 'qbit',
    type: InstanceType.qbittorrent,
    label: 'qBittorrent',
    url: 'https://primary.test',
    alternativeUrl: 'https://alternative.test',
    apiKey: 'user:pass',
  );
  final dio = Dio()
    ..httpClientAdapter = adapter
    ..options.baseUrl = instance.effectiveUrl
    ..options.validateStatus = (status) => status != null && status < 500;
  return QBittorrentService(instance, dio: dio);
}

class _RecordingAdapter implements HttpClientAdapter {
  final Set<String> unavailableHosts;
  final Map<String, int> statusCodes;
  final List<Uri> requests = [];
  final List<String> methods = [];

  _RecordingAdapter({
    Set<String>? unavailableHosts,
    Map<String, int>? statusCodes,
  }) : unavailableHosts = unavailableHosts ?? {},
       statusCodes = statusCodes ?? {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    methods.add(options.method);

    if (unavailableHosts.contains(uri.host)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }

    final statusCode = statusCodes[uri.host] ?? 200;

    // Login endpoint — return 200 with Set-Cookie for reachable hosts.
    if (options.method == 'POST' && uri.path.endsWith('/api/v2/auth/login')) {
      return ResponseBody.fromString(
        'Ok.',
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
          'set-cookie': ['SID=mock-session-cookie; Path=/'],
        },
      );
    }

    final body = uri.path.endsWith('/api/v2/torrents/info')
        ? jsonEncode([
            {'hash': 'abc', 'name': 'Movie 2024', 'size': 1000},
          ])
        : jsonEncode({'ok': uri.host});

    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
