import 'package:flutter/material.dart';

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

  /// Returns the color associated with this status.
  Color get color {
    switch (this) {
      case TorrentStatus.downloading:
        return const Color(0xFF4CAF50); // Green
      case TorrentStatus.uploading:
        return const Color(0xFF42A5F5); // Blue
      case TorrentStatus.queuedDL:
      case TorrentStatus.queuedUP:
      case TorrentStatus.checkingDL:
      case TorrentStatus.checkingUP:
      case TorrentStatus.checkingResumeData:
        return const Color(0xFFFBC02D); // Amber
      case TorrentStatus.stalledDL:
        return const Color(0xFFFB8C00); // Orange
      case TorrentStatus.stalledUP:
        return const Color(0xFFBA68C8); // Light Purple
      case TorrentStatus.pausedDL:
      case TorrentStatus.pausedUP:
        return const Color(0xFF9E9E9E); // Grey
      case TorrentStatus.error:
      case TorrentStatus.missingFiles:
        return const Color(0xFFE53935); // Red
      case TorrentStatus.unknown:
        return const Color(0xFF616161); // Dark Grey
    }
  }
}
