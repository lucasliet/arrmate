import 'package:arrmate/presentation/screens/player/media_player_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAbsoluteSubtitleUri', () {
    test('keeps the reverse-proxy base path of the stream URL', () {
      // Given
      final streamUrl = Uri.parse('http://h/jf/Videos/1/2/stream');

      // When
      final absolute = buildAbsoluteSubtitleUri(
        streamUrl,
        '/Videos/1/2/Subtitles/3/0/Stream.vtt',
      );

      // Then
      expect(
        absolute,
        Uri.parse('http://h/jf/Videos/1/2/Subtitles/3/0/Stream.vtt'),
      );
    });

    test('uses no base path when the stream URL is rooted at /Videos/', () {
      // Given
      final streamUrl = Uri.parse('http://h/Videos/1/2/stream?ApiKey=K');

      // When
      final absolute = buildAbsoluteSubtitleUri(
        streamUrl,
        '/Videos/1/2/Subtitles/3/0/Stream.vtt',
      );

      // Then
      expect(
        absolute.toString(),
        'http://h/Videos/1/2/Subtitles/3/0/Stream.vtt?ApiKey=K',
      );
    });

    test('merges delivery query params without double-encoding the path', () {
      // Given
      final streamUrl = Uri.parse(
        'http://h/jf/Videos/1/2/stream?ApiKey=K&static=true',
      );

      // When
      final absolute = buildAbsoluteSubtitleUri(
        streamUrl,
        '/Videos/1/2/Subtitles/3/0/Stream.vtt?ApiKey=K2&lang=en',
      )!;

      // Then
      // The delivery path's own query must stay in the query string and
      // never leak into (or mangle) the path.
      expect(absolute.path, '/jf/Videos/1/2/Subtitles/3/0/Stream.vtt');
      expect(absolute.toString(), isNot(contains('%3F')));
      expect(absolute.queryParameters, {
        'ApiKey': 'K',
        'static': 'true',
        'lang': 'en',
      });
    });

    test('keeps the stream URL ApiKey over the delivery path one', () {
      // Given
      final streamUrl = Uri.parse('http://h/Videos/1/stream?ApiKey=fresh');

      // When
      final absolute = buildAbsoluteSubtitleUri(
        streamUrl,
        '/Videos/1/Subtitles/2/0/Stream.vtt?ApiKey=stale',
      );

      // Then
      expect(absolute?.queryParameters['ApiKey'], 'fresh');
    });

    test('returns absolute delivery paths parsed as-is', () {
      // Given
      final streamUrl = Uri.parse('http://h/jf/Videos/1/stream?ApiKey=K');
      const delivery = 'https://cdn.example/Subtitles/1.vtt?ApiKey=CDN';

      // When
      final absolute = buildAbsoluteSubtitleUri(streamUrl, delivery);

      // Then
      expect(absolute, Uri.parse(delivery));
    });
  });
}
