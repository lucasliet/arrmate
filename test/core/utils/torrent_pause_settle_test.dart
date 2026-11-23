import 'package:arrmate/core/utils/torrent_pause_settle.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Torrent _torrent(String hash, String state) =>
    Torrent.fromJson({'hash': hash, 'name': hash, 'state': state});

void main() {
  group('torrentPauseSettled', () {
    test('is false while the torrent still reports the old state', () {
      // Given
      final torrents = [_torrent('a', 'downloading')];

      // When
      final settled = torrentPauseSettled(torrents, 'a', paused: true);

      // Then
      expect(settled, isFalse);
    });

    test('is true once the torrent reports the state asked for', () {
      // Given
      final torrents = [_torrent('a', 'downloading')];

      // When
      final settled = torrentPauseSettled(torrents, 'a', paused: false);

      // Then
      expect(settled, isTrue);
    });

    test('is true when the torrent is gone', () {
      // Given
      final torrents = [_torrent('b', 'downloading')];

      // When
      final settled = torrentPauseSettled(torrents, 'a', paused: true);

      // Then
      expect(settled, isTrue);
    });
  });
}
