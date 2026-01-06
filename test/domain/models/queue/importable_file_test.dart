import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportableFileRejection', () {
    test('Deve criar ImportableFileRejection a partir de JSON', () {
      final json = {'reason': 'Sample file detected', 'type': 'sample'};

      final rejection = ImportableFileRejection.fromJson(json);

      expect(rejection.reason, 'Sample file detected');
      expect(rejection.type, 'sample');
    });

    test('Deve usar valores padrão para campos ausentes', () {
      final json = <String, dynamic>{};

      final rejection = ImportableFileRejection.fromJson(json);

      expect(rejection.reason, '');
      expect(rejection.type, 'unknown');
    });

    test('Deve serializar ImportableFileRejection para JSON', () {
      final rejection = ImportableFileRejection(
        reason: 'Sample file detected',
        type: 'sample',
      );

      final json = rejection.toJson();

      expect(json['reason'], 'Sample file detected');
      expect(json['type'], 'sample');
    });

    test(
      'Deve comparar ImportableFileRejection corretamente com Equatable',
      () {
        final rejection1 = ImportableFileRejection(
          reason: 'Sample file',
          type: 'sample',
        );
        final rejection2 = ImportableFileRejection(
          reason: 'Sample file',
          type: 'sample',
        );
        final rejection3 = ImportableFileRejection(
          reason: 'Different',
          type: 'other',
        );

        expect(rejection1, equals(rejection2));
        expect(rejection1, isNot(equals(rejection3)));
      },
    );
  });

  group('ImportableFile', () {
    test('Deve criar ImportableFile a partir de JSON completo para filme', () {
      final json = {
        'id': 1,
        'name': 'Movie.2023.1080p.mkv',
        'path': '/downloads/Movie.2023.1080p.mkv',
        'relativePath': 'Movie.2023.1080p.mkv',
        'size': 8589934592,
        'quality': {
          'quality': {'id': 7, 'name': 'Bluray-1080p'},
        },
        'languages': [
          {'id': 1, 'name': 'English'},
        ],
        'releaseGroup': 'GROUP',
        'downloadId': 'download123',
        'rejections': [
          {'reason': 'Sample', 'type': 'sample'},
        ],
        'movie': {
          'tmdbId': 100,
          'title': 'Test Movie',
          'sortTitle': 'Test Movie',
          'year': 2023,
          'added': '2024-01-01T00:00:00Z',
        },
      };

      final importableFile = ImportableFile.fromJson(json);

      expect(importableFile.id, 1);
      expect(importableFile.name, 'Movie.2023.1080p.mkv');
      expect(importableFile.size, 8589934592);
      expect(importableFile.quality, isNotNull);
      expect(importableFile.languages, isNotNull);
      expect(importableFile.releaseGroup, 'GROUP');
      expect(importableFile.downloadId, 'download123');
      expect(importableFile.rejections.length, 1);
      expect(importableFile.movie, isNotNull);
      expect(importableFile.series, null);
      expect(importableFile.episodes, null);
    });

    test('Deve criar ImportableFile a partir de JSON completo para série', () {
      final json = {
        'id': 2,
        'name': 'Series.S01E01.mkv',
        'size': 4294967296,
        'series': {
          'tvdbId': 200,
          'title': 'Test Series',
          'sortTitle': 'Test Series',
          'year': 2023,
          'added': '2024-01-01T00:00:00Z',
        },
        'episodes': [
          {
            'id': 1,
            'tvdbId': 1,
            'title': 'Pilot',
            'seriesId': 200,
            'seasonNumber': 1,
            'episodeNumber': 1,
          },
        ],
      };

      final importableFile = ImportableFile.fromJson(json);

      expect(importableFile.id, 2);
      expect(importableFile.series, isNotNull);
      expect(importableFile.episodes, isNotNull);
      expect(importableFile.episodes!.length, 1);
      expect(importableFile.movie, null);
    });

    test('Deve identificar hasRejections corretamente', () {
      final withRejections = ImportableFile(
        id: 1,
        size: 1000,
        rejections: [ImportableFileRejection(reason: 'Sample', type: 'sample')],
      );

      final withoutRejections = ImportableFile(
        id: 2,
        size: 1000,
        rejections: [],
      );

      expect(withRejections.hasRejections, true);
      expect(withoutRejections.hasRejections, false);
    });

    test('Deve serializar ImportableFile para JSON', () {
      final importableFile = ImportableFile(
        id: 1,
        name: 'Movie.mkv',
        size: 8589934592,
        downloadId: 'download123',
        rejections: [ImportableFileRejection(reason: 'Sample', type: 'sample')],
      );

      final json = importableFile.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Movie.mkv');
      expect(json['size'], 8589934592);
      expect(json['downloadId'], 'download123');
      expect(json['rejections'], isA<List>());
      expect((json['rejections'] as List).length, 1);
    });

    test('Deve comparar ImportableFile corretamente com Equatable', () {
      final file1 = ImportableFile(id: 1, size: 1000);
      final file2 = ImportableFile(id: 1, size: 1000);
      final file3 = ImportableFile(id: 2, size: 2000);

      expect(file1, equals(file2));
      expect(file1, isNot(equals(file3)));
    });
  });
}
