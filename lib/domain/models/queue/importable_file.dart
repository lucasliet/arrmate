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
  final int size;
  final MediaQuality? quality;
  final List<MediaLanguage>? languages;
  final String? releaseGroup;
  final String? downloadId;
  final List<ImportableFileRejection> rejections;
  final Movie? movie;
  final Series? series;
  final List<Episode>? episodes;

  const ImportableFile({
    required this.id,
    this.name,
    this.path,
    this.relativePath,
    required this.size,
    this.quality,
    this.languages,
    this.releaseGroup,
    this.downloadId,
    this.rejections = const [],
    this.movie,
    this.series,
    this.episodes,
  });

  /// Checks if there are any reasons why this file cannot be imported automatically.
  bool get hasRejections => rejections.isNotEmpty;

  factory ImportableFile.fromJson(Map<String, dynamic> json) {
    return ImportableFile(
      id: json['id'] as int,
      name: json['name'] as String?,
      path: json['path'] as String?,
      relativePath: json['relativePath'] as String?,
      size: json['size'] as int? ?? 0,
      quality: json['quality'] != null
          ? MediaQuality.fromJson(json['quality'] as Map<String, dynamic>)
          : null,
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => MediaLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      releaseGroup: json['releaseGroup'] as String?,
      downloadId: json['downloadId'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (relativePath != null) 'relativePath': relativePath,
      'size': size,
      if (quality != null) 'quality': quality!.toJson(),
      if (languages != null)
        'languages': languages!.map((e) => e.toJson()).toList(),
      if (releaseGroup != null) 'releaseGroup': releaseGroup,
      if (downloadId != null) 'downloadId': downloadId,
      'rejections': rejections.map((e) => e.toJson()).toList(),
      if (movie != null) 'movie': movie!.toJson(),
      if (series != null) 'series': series!.toJson(),
      if (episodes != null)
        'episodes': episodes!.map((e) => e.toJson()).toList(),
    };
  }

  ImportableFile copyWith({
    int? id,
    String? name,
    String? path,
    String? relativePath,
    int? size,
    MediaQuality? quality,
    List<MediaLanguage>? languages,
    String? releaseGroup,
    String? downloadId,
    List<ImportableFileRejection>? rejections,
    Movie? movie,
    Series? series,
    List<Episode>? episodes,
  }) {
    return ImportableFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      relativePath: relativePath ?? this.relativePath,
      size: size ?? this.size,
      quality: quality ?? this.quality,
      languages: languages ?? this.languages,
      releaseGroup: releaseGroup ?? this.releaseGroup,
      downloadId: downloadId ?? this.downloadId,
      rejections: rejections ?? this.rejections,
      movie: movie ?? this.movie,
      series: series ?? this.series,
      episodes: episodes ?? this.episodes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    path,
    relativePath,
    size,
    quality,
    languages,
    releaseGroup,
    downloadId,
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
