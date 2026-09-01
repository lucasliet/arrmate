import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sonarr season monitoring', () {
    test(
      'should send the season flags to the single-series endpoint',
      () async {
        // Given
        // `/series/editor` is a bulk editor over series-level fields only: it
        // answers 200 and drops any season sent to it, which is what left the
        // toggle without effect.
        final adapter = _SeriesAdapter();
        final api = SonarrApi(_instance(), _client(adapter));

        // When
        await api.updateSeriesMonitoring(
          _series(
            seasons: const [
              Season(seasonNumber: 1, monitored: false),
              Season(seasonNumber: 2, monitored: true),
            ],
          ),
        );

        // Then
        expect(adapter.putPath, '/api/v3/series/7');
        expect(adapter.putBody?['seasons'], [
          {'seasonNumber': 1, 'monitored': false},
          {'seasonNumber': 2, 'monitored': true},
        ]);
      },
    );

    test(
      'should send the series monitored flag alongside the seasons',
      () async {
        // Given
        final adapter = _SeriesAdapter();
        final api = SonarrApi(_instance(), _client(adapter));

        // When
        await api.updateSeriesMonitoring(
          _series(
            monitored: false,
            seasons: const [
              Season(seasonNumber: 1, monitored: false),
              Season(seasonNumber: 2, monitored: false),
            ],
          ),
        );

        // Then
        expect(adapter.putBody?['monitored'], isFalse);
      },
    );

    test(
      'should keep the fields Sonarr returned that the app does not model',
      () async {
        // Given
        // The body is the resource Sonarr itself returned, so a field Arrmate
        // has no place for must not come back as a default and overwrite it.
        final adapter = _SeriesAdapter();
        final api = SonarrApi(_instance(), _client(adapter));

        // When
        await api.updateSeriesMonitoring(_series());

        // Then
        expect(adapter.putBody?['cleanTitle'], 'testseries');
        expect(adapter.putBody?['path'], '/tv/Test Series');
      },
    );

    test('should leave a season the caller did not send untouched', () async {
      // Given
      final adapter = _SeriesAdapter();
      final api = SonarrApi(_instance(), _client(adapter));

      // When
      await api.updateSeriesMonitoring(
        _series(seasons: const [Season(seasonNumber: 1, monitored: false)]),
      );

      // Then
      final seasons = adapter.putBody?['seasons'] as List;
      expect(seasons.last, {'seasonNumber': 2, 'monitored': true});
    });
  });
}

Series _series({bool monitored = true, List<Season>? seasons}) {
  return Series(
    guid: 7,
    title: 'Test Series',
    sortTitle: 'test series',
    tvdbId: 12345,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2024,
    added: DateTime.utc(2024, 1, 1),
    monitored: monitored,
    seasons:
        seasons ??
        const [
          Season(seasonNumber: 1, monitored: true),
          Season(seasonNumber: 2, monitored: false),
        ],
  );
}

Instance _instance() {
  return Instance(
    id: 'sonarr',
    type: InstanceType.sonarr,
    label: 'Sonarr',
    url: 'https://sonarr.example.com',
    apiKey: 'key',
  );
}

ApiClient _client(_SeriesAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://sonarr.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

/// Answers the series lookup with a resource richer than the app's model and
/// records the update that follows it.
class _SeriesAdapter implements HttpClientAdapter {
  String? putPath;
  Map<String, dynamic>? putBody;

  static const _stored = {
    'id': 7,
    'title': 'Test Series',
    'sortTitle': 'test series',
    'cleanTitle': 'testseries',
    'path': '/tv/Test Series',
    'tvdbId': 12345,
    'status': 'continuing',
    'seriesType': 'standard',
    'year': 2024,
    'runtime': 40,
    'ended': false,
    'seasonFolder': true,
    'useSceneNumbering': false,
    'added': '2024-01-01T00:00:00Z',
    'monitored': true,
    'seasons': [
      {'seasonNumber': 1, 'monitored': true},
      {'seasonNumber': 2, 'monitored': true},
    ],
    'tags': <int>[],
    'genres': <String>[],
    'images': <Map<String, dynamic>>[],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'PUT') {
      putPath = options.uri.path;
      putBody = Map<String, dynamic>.from(options.data as Map);
    }
    return ResponseBody.fromString(
      jsonEncode(_stored),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
