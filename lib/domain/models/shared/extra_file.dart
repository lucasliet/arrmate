import 'package:equatable/equatable.dart';

/// Types of extra files associated with media.
enum ExtraFileType {
  subtitle,
  metadata,
  other;

  static ExtraFileType fromString(String value) {
    return ExtraFileType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExtraFileType.other,
    );
  }
}

/// Represents an extra file (e.g., subtitle) linked to a movie.
class MovieExtraFile extends Equatable {
  final int id;
  final int? movieId;
  final int? movieFileId;
  final String? relativePath;
  final String? extension;
  final ExtraFileType type;

  const MovieExtraFile({
    required this.id,
    this.movieId,
    this.movieFileId,
    this.relativePath,
    this.extension,
    required this.type,
  });

  factory MovieExtraFile.fromJson(Map<String, dynamic> json) {
    return MovieExtraFile(
      id: json['id'] as int,
      movieId: json['movieId'] as int?,
      movieFileId: json['movieFileId'] as int?,
      relativePath: json['relativePath'] as String?,
      extension: json['extension'] as String?,
      type: json['type'] != null
          ? ExtraFileType.fromString(json['type'] as String)
          : ExtraFileType.other,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (movieId != null) 'movieId': movieId,
      if (movieFileId != null) 'movieFileId': movieFileId,
      if (relativePath != null) 'relativePath': relativePath,
      if (extension != null) 'extension': extension,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [
    id,
    movieId,
    movieFileId,
    relativePath,
    extension,
    type,
  ];
}

/// Represents an extra file (e.g., subtitle) linked to a series/episode.
class SeriesExtraFile extends Equatable {
  final int id;
  final int? seriesId;
  final int? seasonNumber;
  final int? episodeFileId;
  final String? relativePath;
  final String? extension;
  final ExtraFileType type;

  const SeriesExtraFile({
    required this.id,
    this.seriesId,
    this.seasonNumber,
    this.episodeFileId,
    this.relativePath,
    this.extension,
    required this.type,
  });

  factory SeriesExtraFile.fromJson(Map<String, dynamic> json) {
    return SeriesExtraFile(
      id: json['id'] as int,
      seriesId: json['seriesId'] as int?,
      seasonNumber: json['seasonNumber'] as int?,
      episodeFileId: json['episodeFileId'] as int?,
      relativePath: json['relativePath'] as String?,
      extension: json['extension'] as String?,
      type: json['type'] != null
          ? ExtraFileType.fromString(json['type'] as String)
          : ExtraFileType.other,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (seriesId != null) 'seriesId': seriesId,
      if (seasonNumber != null) 'seasonNumber': seasonNumber,
      if (episodeFileId != null) 'episodeFileId': episodeFileId,
      if (relativePath != null) 'relativePath': relativePath,
      if (extension != null) 'extension': extension,
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [
    id,
    seriesId,
    seasonNumber,
    episodeFileId,
    relativePath,
    extension,
    type,
  ];
}
