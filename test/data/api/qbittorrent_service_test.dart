import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_error.dart';
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

    test('should use the active candidate URL for getSystemStatus after a '
        'failover (cookie mode)', () async {
      final adapter = _RecordingAdapter(unavailableHosts: {'primary.test'});
      final service = _serviceCookie(adapter);

      // Force a failover so _activeUrl is promoted to the alternative and a
      // session cookie is acquired against it.
      await service.getTorrents();
      adapter.requests.clear();
      adapter.methods.clear();

      final status = await service.getSystemStatus();

      expect(status.version, isNotNull);
      // After failover, getSystemStatus must read against the active
      // alternative only — never falling back to the dead primary. The
      // session cookie is reused, so no re-auth is needed.
      expect(
        adapter.requests.map((uri) => uri.host),
        everyElement('alternative.test'),
      );
      expect(adapter.requests.map((uri) => uri.path), ['/api/v2/app/version']);
    });

    test('should not promote a fallback that returns 401', () async {
      final adapter = _RecordingAdapter(
        unavailableHosts: {'primary.test'},
        statusCodes: {'alternative.test': 401},
      );
      final service = _service(adapter);

      // A rejected credential is an error, not an empty list.
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

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

  group('QBittorrentService start and stop', () {
    test('should stop a torrent through the endpoint qBittorrent 5 '
        'serves', () async {
      // Given
      final adapter = _RecordingAdapter();
      final service = _service(adapter);

      // When
      await service.pauseTorrents(['hash']);

      // Then
      expect(adapter.requests.map((uri) => uri.path), [
        '/api/v2/torrents/stop',
      ]);
    });

    test('should start a torrent through the endpoint qBittorrent 5 '
        'serves', () async {
      // Given
      final adapter = _RecordingAdapter();
      final service = _service(adapter);

      // When
      await service.resumeTorrents(['hash']);

      // Then
      expect(adapter.requests.map((uri) => uri.path), [
        '/api/v2/torrents/start',
      ]);
    });

    test('should fall back to the pre-5.0 endpoint when the new one is '
        'not served', () async {
      // Given
      // The server answers 404 to a name it does not know.
      final adapter = _RecordingAdapter(
        pathStatusCodes: {'/api/v2/torrents/start': 404},
      );
      final service = _service(adapter);

      // When
      await service.resumeTorrents(['hash']);

      // Then
      expect(adapter.requests.map((uri) => uri.path), [
        '/api/v2/torrents/start',
        '/api/v2/torrents/resume',
      ]);
    });

    test('should stop probing the new endpoint once it answered 404', () async {
      // Given
      final adapter = _RecordingAdapter(
        pathStatusCodes: {'/api/v2/torrents/stop': 404},
      );
      final service = _service(adapter);

      // When
      await service.pauseTorrents(['hash']);
      await service.pauseTorrents(['other']);

      // Then
      expect(adapter.requests.map((uri) => uri.path), [
        '/api/v2/torrents/stop',
        '/api/v2/torrents/pause',
        '/api/v2/torrents/pause',
      ]);
    });
  });

  group('QBittorrentService rejected requests', () {
    int infoRequests(_RecordingAdapter adapter) => adapter.requests
        .where((uri) => uri.path == '/api/v2/torrents/info')
        .length;

    test('should fail a listing the server keeps rejecting after one new '
        'login', () async {
      // Given a session the server never accepts
      final adapter = _RecordingAdapter()..respond = (_) => 403;
      final service = _serviceCookie(adapter);

      // When / Then the call fails instead of returning an empty list
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      // And it logged in once to start and once to renew, asking twice at most
      expect(adapter.loginCount, 2);
      expect(infoRequests(adapter), 2);
    });

    test('should fail an action the server keeps rejecting after one new '
        'login', () async {
      final adapter = _RecordingAdapter()..respond = (_) => 403;
      final service = _serviceCookie(adapter);

      await expectLater(
        service.pauseTorrents(['hash']),
        throwsA(isA<UnauthorizedError>()),
      );

      expect(adapter.loginCount, 2);
      expect(
        adapter.requests.where((uri) => uri.path == '/api/v2/torrents/stop'),
        hasLength(2),
      );
    });

    test('should fail a delete the server answers with 404 or 409', () async {
      for (final status in [404, 409]) {
        final adapter = _RecordingAdapter(
          pathStatusCodes: {'/api/v2/torrents/delete': status},
        );
        final service = _serviceCookie(adapter);

        await expectLater(
          service.deleteTorrents(['hash'], deleteFiles: true),
          throwsA(
            isA<DioException>().having(
              (error) => error.response?.statusCode,
              'status',
              status,
            ),
          ),
        );

        // A refusal that is not about credentials is not retried
        expect(adapter.loginCount, 1);
        expect(
          adapter.requests.where(
            (uri) => uri.path == '/api/v2/torrents/delete',
          ),
          hasLength(1),
        );
      }
    });

    test('should fail a listing answered with another 4xx', () async {
      final adapter = _RecordingAdapter(
        pathStatusCodes: {'/api/v2/torrents/info': 400},
      );
      final service = _serviceCookie(adapter);

      await expectLater(service.getTorrents(), throwsA(isA<DioException>()));
    });

    test('should log in once for requests that expire together', () async {
      // Given an established session the server then expires
      final adapter = _RecordingAdapter();
      final service = _serviceCookie(adapter);
      await service.getTorrents();
      expect(adapter.loginCount, 1);
      adapter.respond = (options) =>
          options.headers['Cookie'] == 'SID=session-1' ? 403 : null;

      // When three requests are rejected at the same time
      final results = await Future.wait([
        service.getTorrents(),
        service.getTorrents(),
        service.getTorrents(),
      ]);

      // Then they share one new login and all succeed with it
      expect(adapter.loginCount, 2);
      expect(results.map((torrents) => torrents.length), [1, 1, 1]);
    });

    test(
      'should log in once for requests that start without a session',
      () async {
        final adapter = _RecordingAdapter();
        final service = _serviceCookie(adapter);

        await Future.wait([
          service.getTorrents(),
          service.getTorrents(),
          service.getTorrents(),
        ]);

        expect(adapter.loginCount, 1);
      },
    );

    test('should not log in again when the new login is refused', () async {
      // Given a session that expires and a server that now refuses the login
      final adapter = _RecordingAdapter();
      final service = _serviceCookie(adapter);
      await service.getTorrents();
      adapter.respond = (options) =>
          options.headers['Cookie'] == 'SID=session-1' ? 403 : null;
      adapter.failLoginsFrom = 2;
      final infoBefore = infoRequests(adapter);

      // When
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      // Then it asked for exactly one new login and never retried the request
      expect(adapter.loginCount, 2);
      expect(infoRequests(adapter) - infoBefore, 1);
    });

    test('should not retry with a login when using an API key', () async {
      final adapter = _RecordingAdapter()..respond = (_) => 401;
      final service = _service(adapter);

      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      expect(adapter.loginCount, 0);
      expect(infoRequests(adapter), 1);
    });

    test('should not log in again on later requests after the credentials '
        'were refused', () async {
      // Given a server that refuses the credentials
      final adapter = _RecordingAdapter()..failLoginsFrom = 1;
      final service = _serviceCookie(adapter);
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );
      expect(adapter.loginCount, 1);
      final requestsAfterFirstFailure = adapter.requests.length;

      // When something keeps polling, as the list does after an error
      for (var cycle = 0; cycle < 6; cycle++) {
        await expectLater(
          service.getTorrents(),
          throwsA(isA<UnauthorizedError>()),
        );
      }
      await expectLater(
        service.pauseTorrents(['hash']),
        throwsA(isA<UnauthorizedError>()),
      );

      // Then the server never hears from the client again
      expect(adapter.loginCount, 1);
      expect(adapter.requests.length, requestsAfterFirstFailure);
    });

    test('should log in exactly once more when the user retries', () async {
      final adapter = _RecordingAdapter()..failLoginsFrom = 1;
      final service = _serviceCookie(adapter);
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      service.allowAuthenticationRetry();
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      // One login for the first try and one for the retry, still refused
      expect(adapter.loginCount, 2);
    });

    test('should work again once a retry finds working credentials', () async {
      final adapter = _RecordingAdapter()..failLoginsFrom = 1;
      final service = _serviceCookie(adapter);
      await expectLater(
        service.getTorrents(),
        throwsA(isA<UnauthorizedError>()),
      );

      adapter.failLoginsFrom = null;
      service.allowAuthenticationRetry();

      expect(await service.getTorrents(), hasLength(1));
      expect(await service.getTorrents(), hasLength(1));
      expect(adapter.loginCount, 2);
    });

    test('should let parallel requests share the refused login', () async {
      final adapter = _RecordingAdapter()..failLoginsFrom = 1;
      final service = _serviceCookie(adapter);

      final results = await Future.wait([
        for (var i = 0; i < 3; i++)
          service.getTorrents().then<Object>(
            (_) => 'ok',
            onError: (Object error) => error,
          ),
      ]);

      expect(results, everyElement(isA<UnauthorizedError>()));
      expect(adapter.loginCount, 1);
    });

    test('should keep the username, the password and the URL out of the '
        'error', () async {
      final adapter = _RecordingAdapter()..respond = (_) => 403;
      final service = _serviceCookie(adapter);

      final error = await service.getTorrents().then<Object>(
        (_) => 'no error',
        onError: (Object error) => error,
      );

      expect(error, isA<UnauthorizedError>());
      final message = error.toString();
      expect(message, isNot(contains('user')));
      expect(message, isNot(contains('pass')));
      expect(message, isNot(contains('primary.test')));
    });
  });

  group('QBittorrentService trackers', () {
    test('should parse torrent trackers from the trackers endpoint', () async {
      final adapter = _RecordingAdapter(
        pathBodies: {
          '/api/v2/torrents/trackers': jsonEncode([
            {
              'url': 'https://tracker.example/announce/secret',
              'status': 2,
              'tier': 0,
              'num_peers': 4,
              'num_seeds': 3,
              'num_leeches': 1,
              'num_downloaded': 9,
              'msg': '',
            },
            {'url': '** [DHT] **', 'status': 2},
          ]),
        },
      );
      final service = _service(adapter);

      final trackers = await service.getTorrentTrackers('abc');

      expect(trackers.map((tracker) => tracker.displayName), [
        'tracker.example',
        'DHT',
      ]);
      expect(trackers.first.status, TorrentTrackerStatus.working);
      expect(trackers.first.numSeeds, 3);
      expect(adapter.requests.last.path, '/api/v2/torrents/trackers');
      expect(adapter.requests.last.queryParameters['hash'], 'abc');
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

  /// Status codes keyed by request path, for servers that serve only part of
  /// the API surface.
  final Map<String, int> pathStatusCodes;

  /// Response bodies keyed by request path.
  final Map<String, String> pathBodies;

  final List<Uri> requests = [];
  final List<String> methods = [];

  /// Answers a non-login request with this status; `null` answers normally.
  int? Function(RequestOptions options)? respond;

  /// Number of login requests received.
  int loginCount = 0;

  /// From this login on (1-based), the server rejects the credentials the way
  /// qBittorrent does: `200` with the body `Fails.` and no cookie.
  int? failLoginsFrom;

  _RecordingAdapter({
    Set<String>? unavailableHosts,
    Map<String, int>? statusCodes,
    Map<String, int>? pathStatusCodes,
    Map<String, String>? pathBodies,
  }) : unavailableHosts = unavailableHosts ?? {},
       statusCodes = statusCodes ?? {},
       pathStatusCodes = pathStatusCodes ?? {},
       pathBodies = pathBodies ?? {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    methods.add(options.method);
    // Lets requests started together interleave, like they do on a network.
    await Future<void>.delayed(Duration.zero);

    if (unavailableHosts.contains(uri.host)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }

    final isLogin =
        options.method == 'POST' && uri.path.endsWith('/api/v2/auth/login');
    final statusCode =
        (isLogin ? null : respond?.call(options)) ??
        pathStatusCodes[uri.path] ??
        statusCodes[uri.host] ??
        200;

    // Login endpoint — return 200 with Set-Cookie for reachable hosts.
    if (isLogin) {
      loginCount++;
      if (failLoginsFrom != null && loginCount >= failLoginsFrom!) {
        return ResponseBody.fromString(
          'Fails.',
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.textPlainContentType],
          },
        );
      }
      return ResponseBody.fromString(
        'Ok.',
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.textPlainContentType],
          'set-cookie': ['SID=session-$loginCount; Path=/'],
        },
      );
    }

    final body =
        pathBodies[uri.path] ??
        (uri.path.endsWith('/api/v2/torrents/info')
            ? jsonEncode([
                {'hash': 'abc', 'name': 'Movie 2024', 'size': 1000},
              ])
            : jsonEncode({'ok': uri.host}));

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
