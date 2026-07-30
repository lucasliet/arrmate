import 'package:arrmate/domain/models/movie/movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieRatings', () {
    test('should parse Trakt ratings when provided by Radarr', () {
      // Given
      final json = {
        'imdb': {'votes': 100, 'value': 8.1},
        'trakt': {'votes': 15774, 'value': 7.60574},
      };

      // When
      final ratings = MovieRatings.fromJson(json);

      // Then
      expect(ratings.trakt, const MovieRating(votes: 15774, value: 7.60574));
      expect(ratings.imdb, const MovieRating(votes: 100, value: 8.1));
    });

    test('should leave Trakt rating absent for older payloads', () {
      // Given
      final json = {
        'tmdb': {'votes': 50, 'value': 7.2},
      };

      // When
      final ratings = MovieRatings.fromJson(json);

      // Then
      expect(ratings.trakt, isNull);
    });
  });
}
