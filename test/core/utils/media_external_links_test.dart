import 'package:arrmate/core/utils/media_external_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaExternalLinks movie', () {
    test('should build identifier links with encoded HTTPS paths', () {
      // Given
      const title = 'Spider-Man: No Way Home';

      // When
      final links = MediaExternalLinks.movie(
        title: title,
        imdbId: ' tt10872600 ',
      );

      // Then
      expect(links.map((link) => link.label), ['IMDb', 'Trakt', 'Letterboxd']);
      expect(links.map((link) => link.uri.scheme).toSet(), {'https'});
      expect(links[0].uri.toString(), 'https://www.imdb.com/title/tt10872600/');
      expect(links[1].uri.toString(), 'https://app.trakt.tv/movies/tt10872600');
      expect(
        links[2].uri.toString(),
        'https://letterboxd.com/search/films/Spider-Man:%20No%20Way%20Home/',
      );
    });

    test('should fall back to encoded title searches for invalid IMDb IDs', () {
      // Given
      const title = 'Alien & Predator';

      // When
      final links = MediaExternalLinks.movie(title: title, imdbId: '../unsafe');

      // Then
      expect(links[0].uri.queryParameters, {'s': 'tt', 'q': title});
      expect(links[1].uri.queryParameters, {'m': 'movie', 'q': title});
      expect(links.every((link) => link.uri.scheme == 'https'), isTrue);
    });
  });

  group('MediaExternalLinks series', () {
    test('should build IMDb, Trakt, and TVDB links', () {
      // Given
      const title = 'Severance';

      // When
      final links = MediaExternalLinks.series(
        title: title,
        tvdbId: 371980,
        imdbId: 'tt11280740',
      );

      // Then
      expect(links.map((link) => link.label), ['IMDb', 'Trakt', 'TVDB']);
      expect(links[0].uri.toString(), 'https://www.imdb.com/title/tt11280740/');
      expect(links[1].uri.toString(), 'https://app.trakt.tv/shows/tt11280740');
      expect(links[2].uri.queryParameters, {'tab': 'series', 'id': '371980'});
    });
  });

  group('MediaExternalLinks YouTube trailer', () {
    test('should build a watch URL for a valid video ID', () {
      // Given
      const trailerId = 'dQw4w9WgXcQ';

      // When
      final uri = MediaExternalLinks.youTubeTrailer(trailerId);

      // Then
      expect(uri?.scheme, 'https');
      expect(uri?.host, 'www.youtube.com');
      expect(uri?.queryParameters, {'v': trailerId});
    });

    test('should reject malformed video IDs', () {
      // Given
      const trailerId = 'https://example.com';

      // When
      final uri = MediaExternalLinks.youTubeTrailer(trailerId);

      // Then
      expect(uri, isNull);
    });
  });
}
