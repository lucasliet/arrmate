import 'package:arrmate/core/utils/cross_seed_matcher.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeTorrentName', () {
    test('should lowercase and trim the name', () {
      expect(
        normalizeTorrentName('  Arrival.2016.1080p.BluRay  '),
        'arrival.2016.1080p.bluray',
      );
    });

    test('should make copies of the same release compare equal', () {
      expect(
        normalizeTorrentName('The.Matrix.1999.1080p.mkv'),
        normalizeTorrentName('the.matrix.1999.1080p.mkv '),
      );
    });
  });

  group('partitionCrossSeed', () {
    test('should split source torrents from same-named duplicates', () {
      // Given
      final source = _torrent(hash: 'SOURCEHASH', name: 'The.Matrix.1999.mkv');
      final crossSeed = _torrent(hash: 'DUPEHASH', name: 'the.matrix.1999.mkv');
      final unrelated = _torrent(hash: 'OTHERHASH', name: 'Dune.2021.mkv');

      // When
      final result = partitionCrossSeed(
        [source, crossSeed, unrelated],
        {'sourcehash'},
      );

      // Then
      expect(result.source, [source]);
      expect(result.crossSeed, [crossSeed]);
    });

    test('should match hashes case-insensitively in both directions', () {
      // Given
      final source = _torrent(hash: 'AbCd', name: 'Arrival.2016');

      // When
      final result = partitionCrossSeed([source], {'ABCD'});

      // Then
      expect(result.source, [source]);
      expect(result.crossSeed, isEmpty);
    });

    test('should match duplicates stored under a different save path', () {
      // Given the same release cross-seeded into another folder
      final source = _torrent(
        hash: 'SOURCEHASH',
        name: 'Arrival.2016',
        savePath: '/downloads/movies',
      );
      final crossSeed = _torrent(
        hash: 'DUPEHASH',
        name: 'Arrival.2016',
        savePath: '/elsewhere/cross-seed',
      );

      // When
      final result = partitionCrossSeed([source, crossSeed], {'sourcehash'});

      // Then the save path must not disqualify the duplicate
      expect(result.crossSeed, [crossSeed]);
    });

    test('should never repeat a source torrent as a cross-seed', () {
      // Given two source hashes sharing one release name
      final first = _torrent(hash: 'AAAA', name: 'Arrival.2016');
      final second = _torrent(hash: 'BBBB', name: 'Arrival.2016');

      // When
      final result = partitionCrossSeed([first, second], {'aaaa', 'bbbb'});

      // Then
      expect(result.source, [first, second]);
      expect(result.crossSeed, isEmpty);
    });

    test('should return nothing when no source hash is given', () {
      // Given
      final torrent = _torrent(hash: 'AAAA', name: 'Arrival.2016');

      // When
      final result = partitionCrossSeed([torrent], const {});

      // Then
      expect(result.source, isEmpty);
      expect(result.crossSeed, isEmpty);
    });

    test('should contribute no name for a hash absent from the client', () {
      // Given a source hash the client no longer holds
      final other = _torrent(hash: 'BBBB', name: 'Arrival.2016');

      // When
      final result = partitionCrossSeed([other], {'aaaa'});

      // Then nothing can be inferred without the source torrent present
      expect(result.source, isEmpty);
      expect(result.crossSeed, isEmpty);
    });
  });
}

Torrent _torrent({
  required String hash,
  required String name,
  String savePath = '/downloads',
}) {
  return Torrent(
    hash: hash,
    name: name,
    size: 1000,
    progress: 1.0,
    dlspeed: 0,
    upspeed: 0,
    eta: 0,
    ratio: 1,
    status: TorrentStatus.uploading,
    state: 'uploading',
    tags: const [],
    savePath: savePath,
    numSeeds: 1,
    numLeechs: 0,
    downloaded: 1000,
    uploaded: 1000,
    amountLeft: 0,
    addedOn: 1700000000,
    priority: 0,
  );
}
