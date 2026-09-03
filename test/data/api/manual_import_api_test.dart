import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/core/network/api_client.dart';
import 'package:arrmate/core/network/api_error.dart';
import 'package:arrmate/data/api/radarr_api.dart';
import 'package:arrmate/data/api/sonarr_api.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Radarr manual import', () {
    test('should identify the movie by a flat id', () async {
      // Given
      // The command reads `movieId` and ignores the nested `movie` resource,
      // so posting the resource verbatim left the id at its default and Radarr
      // answered `Movie with ID 0 does not exist`.
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));

      // When
      await api.manualImport([ImportableFile.fromJson(_movieResource())]);

      // Then
      expect(adapter.path, '/api/v3/command');
      expect(adapter.body?['name'], 'ManualImport');
      expect(adapter.files?.single['movieId'], 12);
    });

    test('should send only the fields the command declares', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));

      // When
      await api.manualImport([ImportableFile.fromJson(_movieResource())]);

      // Then
      final file = adapter.files!.single;
      expect(file.keys, [
        'path',
        'folderName',
        'movieId',
        'quality',
        'languages',
        'releaseGroup',
        'indexerFlags',
        'downloadId',
      ]);
      expect(file['path'], '/downloads/Movie.2024.1080p.mkv');
      expect(file['folderName'], 'Movie.2024.1080p');
      expect(file['releaseGroup'], 'GROUP');
      expect(file['indexerFlags'], 8);
      expect(file['downloadId'], 'ABC123');
      expect(file['languages'], [
        {'id': 1, 'name': 'English'},
      ]);
      expect((file['quality'] as Map)['quality'], {
        'id': 7,
        'name': 'Bluray-1080p',
      });
    });

    test('should let the server move the file by default', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));

      // When
      await api.manualImport([ImportableFile.fromJson(_movieResource())]);

      // Then
      expect(adapter.body?['importMode'], 'auto');
    });

    test('should copy the file when the source has to stay put', () async {
      // Given
      // `auto` moves the file whenever the server does not recognise a download
      // that must keep it, which pulls the data out from under a live torrent.
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));

      // When
      await api.manualImport([
        ImportableFile.fromJson(_movieResource()),
      ], copyFiles: true);

      // Then
      expect(adapter.body?['importMode'], 'copy');
    });

    test('should refuse a file whose movie is not in the library', () async {
      // Given
      // [Movie.id] falls back to an id derived from the TMDB one, and importing
      // against that would target a movie Radarr never had.
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));
      final resource = _movieResource()
        ..['movie'] = {
          'tmdbId': 555,
          'title': 'Test Movie',
          'sortTitle': 'test movie',
          'year': 2024,
          'added': '2024-01-01T00:00:00Z',
        };

      // When / Then
      await expectLater(
        () => api.manualImport([ImportableFile.fromJson(resource)]),
        throwsA(isA<MissingDataError>()),
      );
      expect(adapter.path, isNull);
    });

    test('should name every file that has no movie linked', () async {
      // Given
      // Naming only the first one costs the user a round of fix-and-retry for
      // each remaining file, and nothing is imported meanwhile.
      final adapter = _CommandAdapter();
      final api = RadarrApi(_instance(InstanceType.radarr), _client(adapter));
      final first = _movieResource()
        ..['name'] = 'First.mkv'
        ..remove('movie');
      final second = _movieResource()
        ..['name'] = 'Second.mkv'
        ..remove('movie');

      // When / Then
      await expectLater(
        () => api.manualImport([
          ImportableFile.fromJson(first),
          ImportableFile.fromJson(_movieResource()),
          ImportableFile.fromJson(second),
        ]),
        throwsA(
          isA<MissingDataError>().having(
            (error) => error.message,
            'message',
            'No movie is linked to First.mkv, Second.mkv',
          ),
        ),
      );
      expect(adapter.path, isNull);
    });
  });

  group('Sonarr manual import', () {
    test('should identify the series and episodes by flat ids', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));

      // When
      await api.manualImport([ImportableFile.fromJson(_episodeResource())]);

      // Then
      expect(adapter.path, '/api/v3/command');
      expect(adapter.files?.single['seriesId'], 42);
      expect(adapter.files?.single['episodeIds'], [301, 302]);
    });

    test('should send only the fields the command declares', () async {
      // Given
      final adapter = _CommandAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));

      // When
      await api.manualImport([ImportableFile.fromJson(_episodeResource())]);

      // Then
      final file = adapter.files!.single;
      expect(file.keys, [
        'path',
        'folderName',
        'seriesId',
        'episodeIds',
        'episodeFileId',
        'quality',
        'languages',
        'releaseGroup',
        'indexerFlags',
        'releaseType',
        'downloadId',
      ]);
      expect(file['episodeFileId'], 99);
      expect(file['releaseType'], 'seasonPack');
      expect(file['indexerFlags'], 8);
      expect(file['downloadId'], 'DEF456');
    });

    test('should refuse a file with no episode attached to it', () async {
      // Given
      // Sonarr grabs the episodes from `episodeIds` alone, so an empty list
      // reaches the server as an import with nothing to import.
      final adapter = _CommandAdapter();
      final api = SonarrApi(_instance(InstanceType.sonarr), _client(adapter));
      final resource = _episodeResource()..remove('episodes');

      // When / Then
      await expectLater(
        () => api.manualImport([ImportableFile.fromJson(resource)]),
        throwsA(
          isA<MissingDataError>().having(
            (error) => error.message,
            'message',
            'No episode is linked to Series.S01E01E02.mkv',
          ),
        ),
      );
      expect(adapter.path, isNull);
    });
  });
}

/// Builds a `/manualimport` entry the way Radarr answers it.
Map<String, dynamic> _movieResource() {
  return {
    'id': 1,
    'name': 'Movie.2024.1080p.mkv',
    'path': '/downloads/Movie.2024.1080p.mkv',
    'relativePath': 'Movie.2024.1080p.mkv',
    'folderName': 'Movie.2024.1080p',
    'size': 8589934592,
    'quality': {
      'quality': {'id': 7, 'name': 'Bluray-1080p'},
      'revision': {'version': 1},
    },
    'languages': [
      {'id': 1, 'name': 'English'},
    ],
    'releaseGroup': 'GROUP',
    'downloadId': 'ABC123',
    'indexerFlags': 8,
    'rejections': <Map<String, dynamic>>[],
    'movie': {
      'id': 12,
      'tmdbId': 555,
      'title': 'Test Movie',
      'sortTitle': 'test movie',
      'year': 2024,
      'added': '2024-01-01T00:00:00Z',
    },
  };
}

/// Builds a `/manualimport` entry the way Sonarr answers it.
Map<String, dynamic> _episodeResource() {
  return {
    'id': 1,
    'name': 'Series.S01E01E02.mkv',
    'path': '/downloads/Series.S01E01E02.mkv',
    'relativePath': 'Series.S01E01E02.mkv',
    'folderName': 'Series.S01',
    'size': 4294967296,
    'quality': {
      'quality': {'id': 4, 'name': 'HDTV-1080p'},
      'revision': {'version': 1},
    },
    'languages': [
      {'id': 1, 'name': 'English'},
    ],
    'releaseGroup': 'GROUP',
    'downloadId': 'DEF456',
    'indexerFlags': 8,
    'episodeFileId': 99,
    'releaseType': 'seasonPack',
    'rejections': <Map<String, dynamic>>[],
    'series': {
      'id': 42,
      'tvdbId': 200,
      'title': 'Test Series',
      'sortTitle': 'test series',
      'year': 2024,
      'added': '2024-01-01T00:00:00Z',
    },
    'episodes': [
      {'id': 301, 'seriesId': 42, 'seasonNumber': 1, 'episodeNumber': 1},
      {'id': 302, 'seriesId': 42, 'seasonNumber': 1, 'episodeNumber': 2},
    ],
  };
}

Instance _instance(InstanceType type) {
  return Instance(
    id: type.name,
    type: type,
    label: type.label,
    url: 'https://${type.name}.example.com',
    apiKey: 'key',
  );
}

ApiClient _client(_CommandAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ApiClient(
    baseUrl: 'https://arr.example.com/api/v3',
    headers: const {'X-Api-Key': 'key'},
    dio: dio,
  );
}

/// Records the command posted to the server.
class _CommandAdapter implements HttpClientAdapter {
  String? path;
  Map<String, dynamic>? body;

  /// The files carried by the recorded command.
  List<Map<String, dynamic>>? get files => (body?['files'] as List?)
      ?.map((file) => Map<String, dynamic>.from(file as Map))
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    body = Map<String, dynamic>.from(options.data as Map);
    return ResponseBody.fromString(
      jsonEncode({'id': 1, 'name': 'ManualImport', 'status': 'queued'}),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
