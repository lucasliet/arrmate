import '../../domain/models/models.dart';

/// Pace of the reads that wait for qBittorrent to report a pause or resume.
///
/// qBittorrent accepts a pause or resume at once but only reports the new
/// state on its next refresh (1.5s by default).
const Duration torrentPauseSettleInterval = Duration(seconds: 1);

/// How many reads a pause or resume may take before giving up.
const int torrentPauseSettleAttempts = 5;

/// Whether [torrents] no longer has to be read again for the torrent [hash]
/// to show the [paused] state: it reports that state, or it is gone.
bool torrentPauseSettled(
  Iterable<Torrent> torrents,
  String hash, {
  required bool paused,
}) {
  final reported = torrents
      .where((torrent) => torrent.hash == hash)
      .firstOrNull;
  return reported == null || reported.status.isPaused == paused;
}
