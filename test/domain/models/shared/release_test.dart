import 'package:arrmate/domain/models/shared/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release.fromJson', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'guid': 'guid-123',
        'title': 'Test Release',
        'size': 1024,
        'link': 'http://example.com',
        'indexer': 'Test Indexer',
        'indexerId': '123',
        'seeders': 10,
        'leechers': 5,
        'protocol': 'torrent',
        'rejected': false,
        'rejections': ['Reason 1'],
        'age': 5,
        'indexerFlags': ['Flag1'],
        'score': 100,
        'quality': {
          'quality': {'id': 1, 'name': 'HDTV', 'resolution': 720},
          'revision': {'version': 1, 'real': 0, 'isRepack': false},
        },
      };

      final release = Release.fromJson(json);

      expect(release.guid, 'guid-123');
      expect(release.title, 'Test Release');
      expect(release.score, 100);
      expect(release.rejections, ['Reason 1']);
      expect(release.indexerFlags, ['Flag1']);
    });

    test('should handle "int" rejections gracefully (bug fix)', () {
      final json = {
        'guid': 'guid-123',
        'title': 'Test Release',
        'size': 1024,
        'link': 'http://example.com',
        'indexer': 'Test Indexer',
        'indexerId': '123',
        'seeders': 10,
        'leechers': 5,
        'protocol': 'torrent',
        'rejected': false,
        'rejections': 12345, // Simulate incorrect type from API
        'age': 5,
        'indexerFlags': 0, // Simulate incorrect type from API
        'quality': {
          'quality': {'id': 1, 'name': 'HDTV', 'resolution': 720},
          'revision': {'version': 1, 'real': 0, 'isRepack': false},
        },
      };

      final release = Release.fromJson(json);

      expect(release.rejections, isEmpty);
      expect(release.indexerFlags, isEmpty);
    });

    test('should default score to 0 if missing', () {
      final json = {
        'guid': 'guid-123',
        'title': 'Test Release',
        'size': 1024,
        'link': 'http://example.com',
        'indexer': 'Test Indexer',
        'indexerId': '123',
        'seeders': 10,
        'leechers': 5,
        'protocol': 'torrent',
        'rejected': false,
        'rejections': [],
        'age': 5,
        'indexerFlags': [],
        // score missing
        'quality': {
          'quality': {'id': 1, 'name': 'HDTV', 'resolution': 720},
          'revision': {'version': 1, 'real': 0, 'isRepack': false},
        },
      };

      final release = Release.fromJson(json);

      expect(release.score, 0);
    });
  });
}
