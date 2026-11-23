import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class AddTorrentRequest extends Equatable {
  /// Magnet link, info hash, or HTTP download URL.
  /// Multiple URLs can be separated by newlines.
  final String? urls;

  /// Absolute path to the .torrent file to upload.
  ///
  /// Unused when [torrentFileBytes] is set. The web has no file paths, so
  /// there the picked file only exists as bytes.
  final String? torrentFilePath;

  /// Contents of the .torrent file to upload, when already read.
  final Uint8List? torrentFileBytes;

  /// File name sent with [torrentFileBytes].
  final String? torrentFileName;

  /// Path to save the torrent files.
  final String? savepath;

  /// Category for the torrent.
  final String? category;

  /// Tags to add to the torrent (comma separated).
  final String? tags;

  /// Whether to add the torrent in paused state.
  final bool paused;

  /// Whether to skip hash checking.
  final bool skipChecking;

  const AddTorrentRequest({
    this.urls,
    this.torrentFilePath,
    this.torrentFileBytes,
    this.torrentFileName,
    this.savepath,
    this.category,
    this.tags,
    this.paused = false,
    this.skipChecking = false,
  });

  /// Whether the request carries a .torrent file, by path or by contents.
  bool get hasTorrentFile =>
      torrentFilePath != null || torrentFileBytes != null;

  /// Validates if the request has either URLs or a .torrent file.
  bool get isValid => (urls != null && urls!.isNotEmpty) || hasTorrentFile;

  /// Builds the `/api/v2/torrents/add` form fields.
  ///
  /// The paused flag goes out under both names: qBittorrent 5 only reads
  /// `stopped` and 4.x only reads `paused`, each ignoring the other.
  Map<String, String> toFormFields() {
    final fields = <String, String>{
      'urls': ?urls,
      'savepath': ?savepath,
      'category': ?category,
      'tags': ?tags,
      'paused': paused.toString(),
      'stopped': paused.toString(),
      'skip_checking': skipChecking.toString(),
    };
    return fields;
  }

  @override
  List<Object?> get props => [
    urls,
    torrentFilePath,
    torrentFileBytes,
    torrentFileName,
    savepath,
    category,
    tags,
    paused,
    skipChecking,
  ];
}
