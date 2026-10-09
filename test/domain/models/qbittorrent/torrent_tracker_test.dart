import 'package:arrmate/domain/models/qbittorrent/torrent_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TorrentTracker', () {
    test('should parse an announce tracker', () {
      final tracker = TorrentTracker.fromJson({
        'url': 'https://tracker.example/announce/passkey',
        'status': 2,
        'tier': 1,
        'num_peers': 4,
        'num_seeds': 3,
        'num_leeches': 1,
        'num_downloaded': 9,
        'msg': '',
      });

      expect(tracker.displayName, 'tracker.example');
      expect(tracker.status, TorrentTrackerStatus.working);
      expect(tracker.tier, 1);
      expect(tracker.numSeeds, 3);
      expect(tracker.numLeeches, 1);
      expect(tracker.numPeers, 4);
      expect(tracker.numDownloaded, 9);
      expect(tracker.isSpecial, isFalse);
    });

    test('should keep the announce passkey out of toString', () {
      final tracker = TorrentTracker.fromJson({
        'url': 'https://tracker.example/announce/secret-passkey',
        'status': 2,
        'tier': 1,
      });

      expect(tracker.toString(), isNot(contains('secret-passkey')));
      expect(tracker.toString(), contains('tracker.example'));
    });

    test('should recognize DHT, PeX, and LSD rows', () {
      final dht = TorrentTracker.fromJson({'url': '** [DHT] **', 'status': 2});
      final pex = TorrentTracker.fromJson({'url': '** [PeX] **', 'status': 0});
      final lsd = TorrentTracker.fromJson({
        'url': '** [LSD] **',
        'status': 4,
        'msg': 'offline',
      });

      expect(dht.isSpecial, isTrue);
      expect(dht.displayName, 'DHT');
      expect(pex.displayName, 'PeX');
      expect(pex.status, TorrentTrackerStatus.disabled);
      expect(lsd.displayName, 'LSD');
      expect(lsd.status, TorrentTrackerStatus.notWorking);
      expect(lsd.message, 'offline');
    });

    test('should map unknown status codes', () {
      final tracker = TorrentTracker.fromJson({'url': 'udp://x', 'status': 9});

      expect(tracker.status, TorrentTrackerStatus.unknown);
      expect(tracker.displayName, 'x');
    });

    test('should list working announce trackers before special rows', () {
      final working = TorrentTracker.fromJson({
        'url': 'https://b.example/announce',
        'status': 2,
        'tier': 1,
      });
      final earlierTier = TorrentTracker.fromJson({
        'url': 'https://a.example/announce',
        'status': 2,
        'tier': 0,
      });
      final broken = TorrentTracker.fromJson({
        'url': 'https://c.example/announce',
        'status': 4,
      });
      final dht = TorrentTracker.fromJson({'url': '** [DHT] **', 'status': 2});

      final sorted = [dht, broken, working, earlierTier]
        ..sort(TorrentTracker.compare);

      expect(sorted.map((tracker) => tracker.displayName), [
        'a.example',
        'b.example',
        'c.example',
        'DHT',
      ]);
    });
  });
}
