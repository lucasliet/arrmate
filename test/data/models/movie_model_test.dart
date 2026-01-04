import 'package:flutter_test/flutter_test.dart';
import 'package:arrmate/data/models/models.dart';

void main() {
  group('Movie Model', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'id': 1,
        'tmdbId': 12345,
        'title': 'Test Movie',
        'year': 2023,
        'monitored': true,
        'hasFile': false,
        'isAvailable': false,
        'status': 'released',
        'added': '2023-01-01T00:00:00Z',
        'qualityProfileId': 1,
        'images': [
        {
          'coverType': 'poster',
          'url': '/poster.jpg',
          'remoteUrl': 'http://tmdb.org/poster.jpg'
        }
      ]
      };

      final movie = Movie.fromJson(json);

      expect(movie.id, 1);
      expect(movie.title, 'Test Movie');
      expect(movie.year, 2023);
      expect(movie.monitored, true);
      expect(movie.status, MovieStatus.released);
      expect(movie.images.length, 1);
      expect(movie.images.first.coverType, 'poster');
      expect(movie.images.first.url, '/poster.jpg');
      expect(movie.images.first.remoteUrl, 'http://tmdb.org/poster.jpg');
      expect(movie.remotePoster, 'http://tmdb.org/poster.jpg');
    });

    test('should parse remoteUrl correctly', () {
      final json = {
        'id': 3,
        'tmdbId': 111,
        'title': 'Remote Poster Movie',
        'year': 2024,
        'monitored': true,
        'hasFile': false,
        'isAvailable': true,
        'status': 'announced',
        'added': '2023-01-01T00:00:00Z',
        'qualityProfileId': 1,
        'images': [
          {
            'coverType': 'poster',
            'url': '/local.jpg',
            'remoteUrl': 'http://remote.jpg'
          }
        ]
      };

      final movie = Movie.fromJson(json);
      expect(movie.images.first.remoteUrl, 'http://remote.jpg');
      expect(movie.remotePoster, 'http://remote.jpg');
    });

    test('should handle nullable fields', () {
      final json = {
        'id': 2,
        'tmdbId': 67890,
        'title': 'Nullable Movie',
        'year': 2024,
        'monitored': false,
        'hasFile': false,
        'isAvailable': false,
        'status': 'announced',
        'added': '2023-02-01T00:00:00Z',
        'qualityProfileId': 1,
        'images': []
      };

      final movie = Movie.fromJson(json);

      expect(movie.overview, null);
      expect(movie.studio, null);
      expect(movie.runtime, 0);
    });
  });
}
