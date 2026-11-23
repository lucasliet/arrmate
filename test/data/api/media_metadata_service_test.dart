import 'dart:convert';
import 'dart:typed_data';

import 'package:arrmate/data/api/media_metadata_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.payload);

  final Object payload;
  final requested = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri);
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _person(
  String name,
  int order, {
  String? character,
  String? job,
  String? department,
  String? image,
}) => {
  'Name': name,
  'Order': order,
  'Character': ?character,
  'Job': ?job,
  'Department': ?department,
  'Images': [
    if (image != null) {'CoverType': 'Headshot', 'Url': image},
  ],
};

void main() {
  group('MediaMetadataService', () {
    group('parseMovieDetails', () {
      test('should read the titles and the cast in billing order', () {
        // Given
        final json = {
          'Title': "The Shadow's Edge",
          'OriginalTitle': '捕风追影',
          'Credits': {
            'Cast': [
              _person('Second', 1, character: 'Thief'),
              _person(
                'First',
                0,
                character: 'Detective',
                image: 'https://image.tmdb.org/t/p/original/first.jpg',
              ),
            ],
            'Crew': <dynamic>[],
          },
        };

        // When
        final details = MediaMetadataService.parseMovieDetails(json);

        // Then
        expect(details.englishTitle, "The Shadow's Edge");
        expect(details.originalTitle, '捕风追影');
        expect(details.cast, const [
          MediaCredit(
            name: 'First',
            role: 'Detective',
            imageUrl: 'https://image.tmdb.org/t/p/w185/first.jpg',
          ),
          MediaCredit(name: 'Second', role: 'Thief'),
        ]);
      });

      test('should merge the jobs of a person and list directors first', () {
        // Given
        final json = {
          'Credits': {
            'Crew': [
              _person('Editor', 0, job: 'Editor', department: 'Editing'),
              _person('Auteur', 1, job: 'Writer', department: 'Writing'),
              _person('Auteur', 2, job: 'Director', department: 'Directing'),
              _person('Money', 3, job: 'Producer', department: 'Production'),
            ],
          },
        };

        // When
        final details = MediaMetadataService.parseMovieDetails(json);

        // Then
        expect(details.crew, const [
          MediaCredit(name: 'Auteur', role: 'Director, Writer'),
          MediaCredit(name: 'Money', role: 'Producer'),
          MediaCredit(name: 'Editor', role: 'Editor'),
        ]);
      });

      test('should cap the cast and the crew', () {
        // Given
        final json = {
          'Credits': {
            'Cast': [for (var i = 0; i < 40; i++) _person('Actor $i', i)],
            'Crew': [
              for (var i = 0; i < 40; i++) _person('Crew $i', i, job: 'Grip'),
            ],
          },
        };

        // When
        final details = MediaMetadataService.parseMovieDetails(json);

        // Then
        expect(details.cast, hasLength(MediaMetadataService.maxCast));
        expect(details.crew, hasLength(MediaMetadataService.maxCrew));
      });

      test('should tolerate a payload without credits or with bad entries', () {
        // Given
        final json = {
          'Title': ' ',
          'Credits': {
            'Cast': [
              'garbage',
              {'Name': null},
              {'Name': 'Only Name'},
            ],
            'Crew': null,
          },
        };

        // When
        final details = MediaMetadataService.parseMovieDetails(json);
        final empty = MediaMetadataService.parseMovieDetails(const {});

        // Then
        expect(details.englishTitle, isNull);
        expect(details.cast, const [MediaCredit(name: 'Only Name')]);
        expect(details.crew, isEmpty);
        expect(empty, const MediaPreviewDetails());
      });
    });

    group('parseSeriesDetails', () {
      test('should read the actors', () {
        // Given
        final json = {
          'title': 'Breaking Bad',
          'actors': [
            {
              'name': 'Bryan Cranston',
              'character': 'Walter White',
              'image': 'https://artworks.thetvdb.com/person.jpg',
            },
            {'name': 'Anna Gunn'},
          ],
        };

        // When
        final details = MediaMetadataService.parseSeriesDetails(json);

        // Then
        expect(details.originalTitle, isNull);
        expect(details.crew, isEmpty);
        expect(details.cast, const [
          MediaCredit(
            name: 'Bryan Cranston',
            role: 'Walter White',
            imageUrl: 'https://artworks.thetvdb.com/person.jpg',
          ),
          MediaCredit(name: 'Anna Gunn'),
        ]);
      });
    });

    group('requests', () {
      test('should ask the Radarr metadata server for a movie', () async {
        // Given
        final adapter = _JsonAdapter({'Title': 'Interstellar'});
        final service = MediaMetadataService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        // When
        final details = await service.getMovieDetails(157336);

        // Then
        expect(
          adapter.requested.single.toString(),
          'https://api.radarr.video/v1/movie/157336',
        );
        expect(details.englishTitle, 'Interstellar');
      });

      test('should ask the Sonarr metadata server for a series', () async {
        // Given
        final adapter = _JsonAdapter({
          'actors': [
            {'name': 'Bryan Cranston'},
          ],
        });
        final service = MediaMetadataService(
          dio: Dio()..httpClientAdapter = adapter,
        );

        // When
        final details = await service.getSeriesDetails(81189);

        // Then
        expect(
          adapter.requested.single.toString(),
          'https://skyhook.sonarr.tv/v1/tvdb/shows/en/81189',
        );
        expect(details.cast.single.name, 'Bryan Cranston');
      });
    });
  });
}
