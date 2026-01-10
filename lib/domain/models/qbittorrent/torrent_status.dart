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

  bool get isActive =>
      this == TorrentStatus.downloading ||
      this == TorrentStatus.uploading ||
      this == TorrentStatus.checkingDL ||
      this == TorrentStatus.checkingUP;

  bool get isPaused =>
      this == TorrentStatus.pausedDL || this == TorrentStatus.pausedUP;

  bool get hasError =>
      this == TorrentStatus.error || this == TorrentStatus.missingFiles;
}
