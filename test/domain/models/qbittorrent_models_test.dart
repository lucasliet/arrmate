import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentStatus', () {
    test('should parse correctly', () {
      expect(TorrentStatus.parse('downloading'), TorrentStatus.downloading);
      expect(
        TorrentStatus.parse('upLOading'),
        TorrentStatus.uploading,
      ); // case insensitive check
      expect(TorrentStatus.parse('pausedDL'), TorrentStatus.pausedDL);
      expect(TorrentStatus.parse('unknown_status'), TorrentStatus.unknown);
    });

    test('isActive should be correct', () {
      expect(TorrentStatus.downloading.isActive, true);
      expect(TorrentStatus.uploading.isActive, true);
      expect(TorrentStatus.pausedDL.isActive, false);
    });
  });

  group('AddTorrentRequest', () {
    test('should be valid with magnet', () {
      final req = AddTorrentRequest(urls: 'magnet:?xt=urn:btih:...');
      expect(req.isValid, true);
    });

    test('should be valid with file', () {
      final req = AddTorrentRequest(torrentFilePath: '/path/to/file.torrent');
      expect(req.isValid, true);
    });

    test('should be invalid without source', () {
      final req = AddTorrentRequest();
      expect(req.isValid, false);
    });
  });
}
