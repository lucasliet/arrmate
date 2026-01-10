import 'package:equatable/equatable.dart';

class AddTorrentRequest extends Equatable {
  /// Magnet link, info hash, or HTTP download URL.
  /// Multiple URLs can be separated by newlines.
  final String? urls;

  /// Absolute path to the .torrent file to upload.
  final String? torrentFilePath;

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
    this.savepath,
    this.category,
    this.tags,
    this.paused = false,
    this.skipChecking = false,
  });

  /// Validates if the request has either URLs or a file path.
  bool get isValid =>
      (urls != null && urls!.isNotEmpty) || torrentFilePath != null;

  Map<String, String> toFormFields() {
    final fields = <String, String>{
      if (urls != null) 'urls': urls!,
      if (savepath != null) 'savepath': savepath!,
      if (category != null) 'category': category!,
      if (tags != null) 'tags': tags!,
      'paused': paused.toString(),
      'skip_checking': skipChecking.toString(),
    };
    return fields;
  }

  @override
  List<Object?> get props => [
    urls,
    torrentFilePath,
    savepath,
    category,
    tags,
    paused,
    skipChecking,
  ];
}
