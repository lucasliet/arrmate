/// Represents the status of a torrent in qBittorrent.
enum TorrentStatus {
  downloading,
  uploading,
  stalledDL,
  stalledUP,
  pausedDL,
  pausedUP,
  queuedDL,
  queuedUP,
  checkingDL,
  checkingUP,
  checkingResumeData,
  missingFiles,
  error,
  unknown;

  /// Parses a string state from the API into a [TorrentStatus].
  ///
  /// @param state The state string from qBittorrent API.
  /// @return The corresponding [TorrentStatus], or [unknown] if not recognized.
  static TorrentStatus parse(String state) {
    switch (state.toLowerCase()) {
      case 'downloading':
      case 'forceddl':
        return TorrentStatus.downloading;
      case 'uploading':
      case 'forcedup':
        return TorrentStatus.uploading;
      case 'stalleddl':
        return TorrentStatus.stalledDL;
      case 'stalledup':
        return TorrentStatus.stalledUP;
      case 'pauseddl':
        return TorrentStatus.pausedDL;
      case 'pausedup':
        return TorrentStatus.pausedUP;
      case 'queueddl':
        return TorrentStatus.queuedDL;
      case 'queuedup':
        return TorrentStatus.queuedUP;
      case 'checkingdl':
        return TorrentStatus.checkingDL;
      case 'checkingup':
        return TorrentStatus.checkingUP;
      case 'checkingresumedata':
        return TorrentStatus.checkingResumeData;
      case 'missingfiles':
        return TorrentStatus.missingFiles;
      case 'error':
        return TorrentStatus.error;
      default:
        return TorrentStatus.unknown;
    }
  }

  /// Returns a human-readable label for the status.
  String get label {
    switch (this) {
      case TorrentStatus.downloading:
        return 'Downloading';
      case TorrentStatus.uploading:
        return 'Seeding';
      case TorrentStatus.stalledDL:
        return 'Stalled (DL)';
      case TorrentStatus.stalledUP:
        return 'Stalled (UP)';
      case TorrentStatus.pausedDL:
        return 'Paused (DL)';
      case TorrentStatus.pausedUP:
        return 'Paused (UP)';
      case TorrentStatus.queuedDL:
        return 'Queued (DL)';
      case TorrentStatus.queuedUP:
        return 'Queued (UP)';
      case TorrentStatus.checkingDL:
      case TorrentStatus.checkingUP:
      case TorrentStatus.checkingResumeData:
        return 'Checking';
      case TorrentStatus.missingFiles:
        return 'Missing Files';
      case TorrentStatus.error:
        return 'Error';
      case TorrentStatus.unknown:
        return 'Unknown';
    }
  }

  /// Returns true if the torrent is currently active (downloading, seeding, or checking).
  bool get isActive =>
      this == TorrentStatus.downloading ||
      this == TorrentStatus.uploading ||
      this == TorrentStatus.checkingDL ||
      this == TorrentStatus.checkingUP;

  /// Returns true if the torrent is paused.
  bool get isPaused =>
      this == TorrentStatus.pausedDL || this == TorrentStatus.pausedUP;

  /// Returns true if the torrent has encountered an error or is missing files.
  bool get hasError =>
      this == TorrentStatus.error || this == TorrentStatus.missingFiles;
}
