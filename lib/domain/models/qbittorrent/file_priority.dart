import 'package:flutter/material.dart';

/// Priority levels for a file in a torrent (qBittorrent specific).
enum FilePriority {
  doNotDownload(0, 'Do Not Download', Icons.file_download_off),
  low(1, 'Low Priority', Icons.arrow_downward),
  normal(2, 'Normal Priority', Icons.remove),
  high(6, 'High Priority', Icons.arrow_upward),
  maximal(7, 'Maximal Priority', Icons.priority_high);

  final int value;
  final String label;
  final IconData icon;

  const FilePriority(this.value, this.label, this.icon);

  /// Helper to check if file is marked for download
  bool get isDownloading => this != FilePriority.doNotDownload;

  /// Parse from integer value
  static FilePriority fromValue(int value) {
    return FilePriority.values.firstWhere(
      (e) => e.value == value,
      // Default to normal if unknown value
      orElse: () => FilePriority.normal,
    );
  }
}
