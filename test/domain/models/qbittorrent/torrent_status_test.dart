import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentStatus', () {
    test('should read the stopped states qBittorrent 5 reports', () {
      // Given
      // Version 5 renamed the paused states. Unrecognised, they fell through to
      // `unknown`, and the UI offered to pause a torrent already stopped.
      const states = {
        'stoppedDL': TorrentStatus.pausedDL,
        'stoppedUP': TorrentStatus.pausedUP,
      };

      // When / Then
      for (final entry in states.entries) {
        expect(TorrentStatus.parse(entry.key), entry.value);
        expect(TorrentStatus.parse(entry.key).isPaused, isTrue);
      }
    });

    test('should keep reading the states of earlier versions', () {
      // Given / When / Then
      expect(TorrentStatus.parse('pausedDL'), TorrentStatus.pausedDL);
      expect(TorrentStatus.parse('pausedUP'), TorrentStatus.pausedUP);
    });

    test('should treat a stopped seed as seeding', () {
      // Given
      // The torrent finished downloading, so it belongs with the seeds even
      // while it is halted.

      // When
      final status = TorrentStatus.parse('stoppedUP');

      // Then
      expect(status.isSeeding, isTrue);
      expect(status.label, 'Paused (UP)');
    });
  });
}
