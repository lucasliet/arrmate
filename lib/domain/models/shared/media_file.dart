import 'package:equatable/equatable.dart';

class MediaFile extends Equatable {
  final int id;
  final String? relativePath;
  final String? path;
  final int size;
  final DateTime dateAdded;

  final MediaQuality? quality;
  final List<MediaLanguageInfo>? languages;

  const MediaFile({
    required this.id,
    this.relativePath,
    this.path,
    required this.size,
    required this.dateAdded,
    this.quality,
    this.languages,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] as int,
      relativePath: json['relativePath'] as String?,
      path: json['path'] as String?,
      size: json['size'] as int? ?? 0,
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      quality: json['quality'] != null
          ? MediaQuality.fromJson(json['quality'] as Map<String, dynamic>)
          : null,
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => MediaLanguageInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (relativePath != null) 'relativePath': relativePath,
      if (path != null) 'path': path,
      'size': size,
      'dateAdded': dateAdded.toIso8601String(),
      if (quality != null) 'quality': quality!.toJson(),
      if (languages != null)
        'languages': languages!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    relativePath,
    path,
    size,
    dateAdded,
    quality,
    languages,
  ];
}

class MediaQuality extends Equatable {
  final QualityInfo quality;
  final int revision;

  const MediaQuality({required this.quality, required this.revision});

  factory MediaQuality.fromJson(Map<String, dynamic> json) {
    return MediaQuality(
      quality: QualityInfo.fromJson(json['quality'] as Map<String, dynamic>),
      revision:
          (json['revision'] as Map<String, dynamic>?)?['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality.toJson(),
      'revision': {'version': revision},
    };
  }

  @override
  List<Object?> get props => [quality, revision];
}

class QualityInfo extends Equatable {
  final int id;
  final String name;
  final String? source;
  final int? resolution;

  const QualityInfo({
    required this.id,
    required this.name,
    this.source,
    this.resolution,
  });

  factory QualityInfo.fromJson(Map<String, dynamic> json) {
    return QualityInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String?,
      resolution: json['resolution'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (source != null) 'source': source,
      if (resolution != null) 'resolution': resolution,
    };
  }

  @override
  List<Object?> get props => [id, name, source, resolution];
}

class MediaLanguageInfo extends Equatable {
  final int id;
  final String name;

  const MediaLanguageInfo({required this.id, required this.name});

  factory MediaLanguageInfo.fromJson(Map<String, dynamic> json) {
    return MediaLanguageInfo(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
}
