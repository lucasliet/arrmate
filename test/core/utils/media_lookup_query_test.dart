import 'package:arrmate/core/utils/media_lookup_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeMediaLookupQuery', () {
    test('should extract IMDb IDs from URLs for both media types', () {
      // Given
      const url = 'https://www.imdb.com/title/tt0816692/?ref_=fn_all_ttl_1';

      // When
      final movie = normalizeMediaLookupQuery(url, MediaLookupType.movie);
      final series = normalizeMediaLookupQuery(url, MediaLookupType.series);

      // Then
      expect(movie, 'imdb:tt0816692');
      expect(series, 'imdb:tt0816692');
    });

    test('should extract TMDB movie and series IDs from URLs', () {
      // Given
      const movieUrl = 'https://www.themoviedb.org/movie/157336-interstellar';
      const seriesUrl = 'https://www.themoviedb.org/tv/1396-breaking-bad';

      // When
      final movie = normalizeMediaLookupQuery(movieUrl, MediaLookupType.movie);
      final series = normalizeMediaLookupQuery(
        seriesUrl,
        MediaLookupType.series,
      );

      // Then
      expect(movie, 'tmdb:157336');
      expect(series, 'tmdb:1396');
    });

    test('should map raw numeric IDs to the catalog provider', () {
      // Given
      const input = ' 81189 ';

      // When
      final movie = normalizeMediaLookupQuery(input, MediaLookupType.movie);
      final series = normalizeMediaLookupQuery(input, MediaLookupType.series);

      // Then
      expect(movie, 'tmdb:81189');
      expect(series, 'tvdb:81189');
    });

    test('should preserve title searches and normalize provider prefixes', () {
      // Given
      const title = '  Breaking Bad  ';
      const providerId = ' IMDb : TT0903747 ';

      // When
      final titleQuery = normalizeMediaLookupQuery(
        title,
        MediaLookupType.series,
      );
      final providerQuery = normalizeMediaLookupQuery(
        providerId,
        MediaLookupType.series,
      );

      // Then
      expect(titleQuery, 'Breaking Bad');
      expect(providerQuery, 'imdb:tt0903747');
    });
  });
}
