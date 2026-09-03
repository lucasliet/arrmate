import 'package:equatable/equatable.dart';

import '../movie/movie.dart';
import '../series/series.dart';
import '../shared/media_file.dart';
import '../shared/media_language.dart';

/// Represents a file waiting for manual import.
class ImportableFile extends Equatable {
  final int id;
  final String? name;
  final String? path;
  final String? relativePath;

  /// Folder the file was found in.
  ///
  /// The server parses release information out of it when the file name alone
  /// does not carry it, so an import keeps whatever the folder revealed.
  final String? folderName;

  final int size;
  final MediaQuality? quality;
  final List<MediaLanguage>? languages;
  final String? releaseGroup;
  final String? downloadId;

  /// Flags the indexer reported for the release, as a bit field.
  ///
  /// They feed custom format scoring, so an import that drops them can land
  /// with a different score than the release was graded with.
  final int? indexerFlags;

  /// File this import replaces, when it is an upgrade over an existing one.
  final int? episodeFileId;

  /// How the release was published, e.g. `singleEpisode` or `seasonPack`.
  final String? releaseType;

  final List<ImportableFileRejection> rejections;
  final Movie? movie;
  final Series? series;
  final List<Episode>? episodes;

  const ImportableFile({
    required this.id,
    this.name,
    this.path,
    this.relativePath,
    this.folderName,
    required this.size,
    this.quality,
    this.languages,
    this.releaseGroup,
    this.downloadId,
    this.indexerFlags,
    this.episodeFileId,
    this.releaseType,
    this.rejections = const [],
    this.movie,
    this.series,
    this.episodes,
  });

  /// Checks if there are any reasons why this file cannot be imported automatically.
  bool get hasRejections => rejections.isNotEmpty;

  /// How to name this file when addressing the user about it.
  String get displayName => name ?? relativePath ?? path ?? 'an unnamed file';

  factory ImportableFile.fromJson(Map<String, dynamic> json) {
    return ImportableFile(
      id: json['id'] as int,
      name: json['name'] as String?,
      path: json['path'] as String?,
      relativePath: json['relativePath'] as String?,
      folderName: json['folderName'] as String?,
      size: json['size'] as int? ?? 0,
      quality: json['quality'] != null
          ? MediaQuality.fromJson(json['quality'] as Map<String, dynamic>)
          : null,
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => MediaLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      releaseGroup: json['releaseGroup'] as String?,
      downloadId: json['downloadId'] as String?,
      indexerFlags: json['indexerFlags'] as int?,
      episodeFileId: json['episodeFileId'] as int?,
      releaseType: json['releaseType'] as String?,
      rejections:
          (json['rejections'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ImportableFileRejection.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      movie: json['movie'] != null
          ? Movie.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
      series: json['series'] != null
          ? Series.fromJson(json['series'] as Map<String, dynamic>)
          : null,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns a copy of this file with [movie] or [downloadId] attached to it.
  ///
  /// Everything the server reported about the file is carried over, so mapping
  /// a file by hand does not cost it the release information the import needs.
  ImportableFile copyWith({Movie? movie, String? downloadId}) {
    return ImportableFile(
      id: id,
      name: name,
      path: path,
      relativePath: relativePath,
      folderName: folderName,
      size: size,
      quality: quality,
      languages: languages,
      releaseGroup: releaseGroup,
      downloadId: downloadId ?? this.downloadId,
      indexerFlags: indexerFlags,
      episodeFileId: episodeFileId,
      releaseType: releaseType,
      rejections: rejections,
      movie: movie ?? this.movie,
      series: series,
      episodes: episodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (relativePath != null) 'relativePath': relativePath,
      if (folderName != null) 'folderName': folderName,
      'size': size,
      if (quality != null) 'quality': quality!.toJson(),
      if (languages != null)
        'languages': languages!.map((e) => e.toJson()).toList(),
      if (releaseGroup != null) 'releaseGroup': releaseGroup,
      if (downloadId != null) 'downloadId': downloadId,
      if (indexerFlags != null) 'indexerFlags': indexerFlags,
      if (episodeFileId != null) 'episodeFileId': episodeFileId,
      if (releaseType != null) 'releaseType': releaseType,
      'rejections': rejections.map((e) => e.toJson()).toList(),
      if (movie != null) 'movie': movie!.toJson(),
      if (series != null) 'series': series!.toJson(),
      if (episodes != null)
        'episodes': episodes!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    path,
    relativePath,
    folderName,
    size,
    quality,
    languages,
    releaseGroup,
    downloadId,
    indexerFlags,
    episodeFileId,
    releaseType,
    rejections,
    movie,
    series,
    episodes,
  ];
}

/// Represents a reason why a file was rejected for automatic import.
class ImportableFileRejection extends Equatable {
  final String reason;
  final String type;

  const ImportableFileRejection({required this.reason, required this.type});

  factory ImportableFileRejection.fromJson(Map<String, dynamic> json) {
    return ImportableFileRejection(
      reason: json['reason'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {'reason': reason, 'type': type};
  }

  @override
  List<Object?> get props => [reason, type];
}
