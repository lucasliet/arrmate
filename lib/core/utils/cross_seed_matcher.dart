import '../../domain/models/qbittorrent/torrent.dart';

/// A torrent list split against a set of known source infohashes.
typedef CrossSeedPartition = ({List<Torrent> source, List<Torrent> crossSeed});

/// Normalizes a torrent name so cross-seed copies of the same release compare
/// equal.
///
/// A cross-seeded torrent keeps the release name but gets a new infohash on
/// every tracker, so the name is the only signal shared by all copies.
String normalizeTorrentName(String name) => name.toLowerCase().trim();

/// Splits [torrents] into the ones whose infohash is in [sourceHashes] and the
/// cross-seed duplicates that share a normalized name with one of them.
///
/// [sourceHashes] may be in any case; the comparison is case-insensitive.
/// Save path, size, file list, tracker and category are deliberately ignored:
/// the same release cross-seeded to another tracker is routinely stored
/// elsewhere and announced differently, while its name stays identical.
CrossSeedPartition partitionCrossSeed(
  List<Torrent> torrents,
  Set<String> sourceHashes,
) {
  if (sourceHashes.isEmpty) {
    return (source: <Torrent>[], crossSeed: <Torrent>[]);
  }

  final normalizedHashes = {
    for (final hash in sourceHashes) hash.toLowerCase(),
  };

  final source = <Torrent>[];
  final sourceHashesFound = <String>{};
  final sourceNames = <String>{};
  for (final torrent in torrents) {
    final hash = torrent.hash.toLowerCase();
    if (!normalizedHashes.contains(hash)) continue;
    source.add(torrent);
    sourceHashesFound.add(hash);
    sourceNames.add(normalizeTorrentName(torrent.name));
  }

  final crossSeed = <Torrent>[];
  for (final torrent in torrents) {
    if (sourceHashesFound.contains(torrent.hash.toLowerCase())) continue;
    if (sourceNames.contains(normalizeTorrentName(torrent.name))) {
      crossSeed.add(torrent);
    }
  }

  return (source: source, crossSeed: crossSeed);
}
