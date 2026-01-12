import 'package:equatable/equatable.dart';

import 'file_priority.dart';

/// Represents a file within a torrent in qBittorrent.
class TorrentFile extends Equatable {
  /// The index of the file in the torrent file list.
  final int index;

  /// The name of the file.
  final String name;

  /// The size of the file in bytes.
  final int size;

  /// Returns the file name (basename) derived from the full path [name].
  String get fileName => name.split(RegExp(r'[/\\]')).last;

  /// The download progress of the file (0.0 to 1.0).
  final double progress;

  /// The priority of the file.
  final FilePriority priority;

  /// Whether this file is the default file in the torrent (optional).
  final bool isSeed;

  /// The piece range (optional).
  final List<int>? pieceRange;

  /// The availability of the file (0.0 to 1.0).
  final double availability;

  const TorrentFile({
    required this.index,
    required this.name,
    required this.size,
    required this.progress,
    required this.priority,
    this.isSeed = false,
    this.pieceRange,
    this.availability = 0.0,
  });

  /// Creates a [TorrentFile] from a JSON map.
  ///
  /// [index] must be provided externally as the API returns a list without explicit IDs usually.
  factory TorrentFile.fromJson(Map<String, dynamic> json, int index) {
    return TorrentFile(
      index: index,
      name: json['name'] as String? ?? 'Unknown',
      size: json['size'] as int? ?? 0,
      progress: (json['progress'] as num? ?? 0).toDouble(),
      priority: FilePriority.fromValue(json['priority'] as int? ?? 1),
      isSeed: json['is_seed'] as bool? ?? false,
      availability: (json['availability'] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    index,
    name,
    size,
    progress,
    priority,
    isSeed,
    availability,
  ];
}
