import 'dart:convert';
import 'dart:io';

import 'package:arrmate/domain/models/shared/media_custom_format.dart';
import 'package:arrmate/domain/models/shared/media_language.dart';
import 'package:arrmate/domain/models/shared/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release.fromJson', () {
    test('should parse a Radarr release payload', () async {
      // Given
      final json = await _loadFixture('radarr_release.json');

      // When
      final release = Release.fromJson(json);

      // Then
      expect(release.customFormatScore, 123);
      expect(release.score, 123);
      expect(release.qualityWeight, 2401);
      expect(release.releaseWeight, 4);
      expect(release.languages, const [MediaLanguage(id: 1, name: 'English')]);
      expect(release.customFormats, const [
        MediaCustomFormat(id: 1, name: 'Foobar 3'),
      ]);
      expect(release.protocol, 'torrent');
      expect(release.indexerFlags, const ['G_Freeleech']);
      expect(release.isFreeleech, isTrue);
      expect(release.mappedEpisodeNumbers, isEmpty);
      expect(release.fullSeason, isFalse);
      expect(release.episodeRequested, isFalse);
    });

    test('should parse a Sonarr release payload', () async {
      // Given
      final json = await _loadFixture('sonarr_release.json');

      // When
      final release = Release.fromJson(json);

      // Then
      expect(release.customFormatScore, 75);
      expect(release.qualityWeight, 1201);
      expect(release.releaseWeight, 14);
      expect(release.languages, const [MediaLanguage(id: 1, name: 'English')]);
      expect(release.customFormats, const [
        MediaCustomFormat(id: 2, name: 'Surround Sound'),
      ]);
      expect(release.protocol, 'torrent');
      expect(release.indexerFlags, const ['Freeleech', 'Internal']);
      expect(release.isFreeleech, isTrue);
      expect(release.mappedEpisodeNumbers, const [1, 2, 3, 4, 5, 6]);
      expect(release.fullSeason, isTrue);
      expect(release.episodeRequested, isTrue);
    });

    test('should handle unsupported collection payloads gracefully', () {
      // Given
      final json = _minimalReleaseJson(
        rejections: 12345,
        indexerFlags: {'unsupported': true},
        languages: 'English',
        customFormats: 'Surround Sound',
        mappedEpisodeNumbers: '1,2',
      );

      // When
      final release = Release.fromJson(json);

      // Then
      expect(release.rejections, isEmpty);
      expect(release.indexerFlags, isEmpty);
      expect(release.languages, isEmpty);
      expect(release.customFormats, isEmpty);
      expect(release.mappedEpisodeNumbers, isEmpty);
      expect(release.isFreeleech, isFalse);
    });

    test('should default optional release metadata', () {
      // Given
      final json = _minimalReleaseJson();

      // When
      final release = Release.fromJson(json);

      // Then
      expect(release.customFormatScore, 0);
      expect(release.qualityWeight, 0);
      expect(release.releaseWeight, 0);
      expect(release.languages, isEmpty);
      expect(release.customFormats, isEmpty);
      expect(release.protocol, 'torrent');
      expect(release.indexerFlags, isEmpty);
      expect(release.mappedEpisodeNumbers, isEmpty);
      expect(release.fullSeason, isFalse);
      expect(release.episodeRequested, isFalse);
    });
  });
}

Future<Map<String, dynamic>> _loadFixture(String name) async {
  final contents = await File('test/fixtures/releases/$name').readAsString();
  return jsonDecode(contents) as Map<String, dynamic>;
}

Map<String, dynamic> _minimalReleaseJson({
  Object? rejections = const <String>[],
  Object? indexerFlags = const <String>[],
  Object? languages = const <Map<String, dynamic>>[],
  Object? customFormats = const <Map<String, dynamic>>[],
  Object? mappedEpisodeNumbers = const <int>[],
}) {
  return {
    'guid': 'guid-123',
    'title': 'Test Release',
    'size': 1024,
    'indexer': 'Test Indexer',
    'indexerId': 123,
    'rejected': false,
    'rejections': rejections,
    'age': 5,
    'indexerFlags': indexerFlags,
    'languages': languages,
    'customFormats': customFormats,
    'mappedEpisodeNumbers': mappedEpisodeNumbers,
    'quality': {
      'quality': {'id': 1, 'name': 'HDTV', 'resolution': 720},
      'revision': {'version': 1, 'real': 0, 'isRepack': false},
    },
  };
}
