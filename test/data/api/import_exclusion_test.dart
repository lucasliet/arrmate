import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Import exclusion deletion parameters', () {
    test('should use addImportExclusion for Radarr movies', () async {
      // Given
      final adapter = _RecordingAdapter();
      final api = RadarrApi(
        _instance(InstanceType.radarr, mode: InstanceMode.slow),
        _client(adapter),
      );

      // When
      await api.deleteMovie(42, addExclusion: true);

      // Then
      expect(adapter.request?.path, '/api/v3/movie/42');
      expect(adapter.request?.queryParameters, {
        'deleteFiles': 'false',
        'addImportExclusion': 'true',
      });
      expect(adapter.options?.receiveTimeout, const Duration(seconds: 300));
      expect(adapter.options?.sendTimeout, const Duration(seconds: 300));
    });

    test('should use addImportListExclusion for Sonarr series', () async {
      // Given
      final adapter = _RecordingAdapter();
      final api = SonarrApi(
        _instance(InstanceType.sonarr, mode: InstanceMode.slow),
        _client(adapter),
      );

      // When
      await api.deleteSeries(42, addExclusion: true);

      // Then
      expect(adapter.request?.path, '/api/v3/series/42');
      expect(adapter.request?.queryParameters, {
        'deleteFiles': 'false',
        'addImportListExclusion': 'true',
      });
      expect(adapter.options?.receiveTimeout, const Duration(seconds: 300));
      expect(adapter.options?.sendTimeout, const Duration(seconds: 300));
    });
  });

  group('Sonarr episode operations', () {
    test('should delete episode files with the bulk endpoint', () async {
      // Given
      final adapter = _RecordingAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));

      // When
      await api.deleteSeriesFiles([10, 20]);

      // Then
      expect(adapter.request?.path, '/api/v3/episodefile/bulk');
      expect(adapter.data, {
        'episodeFileIds': [10, 20],
      });
    });

    test(
      'should update episode monitoring with the monitor endpoint',
      () async {
        // Given
        final adapter = _RecordingAdapter();
        final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));

        // When
        await api.monitorEpisodes([100, 200], false);

        // Then
        expect(adapter.request?.path, '/api/v3/episode/monitor');
        expect(adapter.data, {
          'episodeIds': [100, 200],
          'monitored': false,
        });
      },
    );
  });

  group('Targeted media editors', () {
    test('should update a movie through the editor endpoint', () async {
      // Given
      final adapter = _RecordingAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));
      final movie = Movie(
        guid: 42,
        tmdbId: 100,
        title: 'Movie',
        sortTitle: 'Movie',
        year: 2024,
        runtime: 120,
        status: MovieStatus.released,
        isAvailable: true,
        minimumAvailability: MovieStatus.inCinemas,
        monitored: true,
        qualityProfileId: 3,
        rootFolderPath: '/movies',
        added: DateTime(2024),
        tags: const [4, 5],
      );

      // When
      final result = await api.updateMovie(movie, moveFiles: true);

      // Then
      expect(result, movie);
      expect(adapter.request?.path, '/api/v3/movie/editor');
      expect(adapter.data, {
        'movieIds': [42],
        'monitored': true,
        'qualityProfileId': 3,
        'minimumAvailability': 'inCinemas',
        'rootFolderPath': '/movies',
        'tags': [4, 5],
        'applyTags': 'replace',
        'moveFiles': true,
      });
    });

    test('should update a series through the editor endpoint', () async {
      // Given
      final adapter = _RecordingAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));
      final series = Series(
        guid: 42,
        title: 'Series',
        sortTitle: 'Series',
        tvdbId: 200,
        status: SeriesStatus.continuing,
        seriesType: SeriesType.anime,
        qualityProfileId: 7,
        rootFolderPath: '/series',
        year: 2024,
        added: DateTime(2024),
        monitored: true,
        monitorNewItems: SeriesMonitorNewItems.all,
        seasonFolder: false,
        tags: const [8, 9],
      );

      // When
      final result = await api.updateSeries(series, moveFiles: true);

      // Then
      expect(result, series);
      expect(adapter.request?.path, '/api/v3/series/editor');
      expect(adapter.data, {
        'seriesIds': [42],
        'monitored': true,
        'monitorNewItems': 'all',
        'seriesType': 'anime',
        'seasonFolder': false,
        'qualityProfileId': 7,
        'rootFolderPath': '/series',
        'tags': [8, 9],
        'applyTags': 'replace',
        'moveFiles': true,
      });
    });
  });
}

Instance _instance(
  InstanceType type, {
  InstanceMode mode = InstanceMode.normal,
}) {
  return Instance(
    id: type.name,
    type: type,
    mode: mode,
    label: type.label,
    url: 'https://${type.name}.example.com',
    apiKey: 'key',
  );
}

ApiClient _client(_RecordingAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://arr.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  Uri? request;
  RequestOptions? options;
  dynamic data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options.uri;
    this.options = options;
    data = options.data;
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}
