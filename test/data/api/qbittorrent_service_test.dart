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
    ..options.baseUrl = instance.effectiveUrl;
  return QBittorrentService(instance, dio: dio);
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

    final statusCode = statusCodes[uri.host] ?? 200;
    final body = uri.path == '/api/v2/torrents/info'
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
