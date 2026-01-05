import 'package:equatable/equatable.dart';
import 'package:arrmate/domain/models/shared/media_custom_format.dart';

class MediaFile extends Equatable {
  final int id;
  final String? relativePath;
  final String? path;
  final int size;
  final DateTime dateAdded;

  final FileMediaInfo? mediaInfo;
  final MediaQuality? quality;
  final List<MediaLanguageInfo>? languages;
  final List<MediaCustomFormat>? customFormats;
  final int? customFormatScore;

  const MediaFile({
    required this.id,
    this.relativePath,
    this.path,
    required this.size,
    required this.dateAdded,
    this.mediaInfo,
    this.quality,
    this.languages,
    this.customFormats,
    this.customFormatScore,
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
      mediaInfo: json['mediaInfo'] != null
          ? FileMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>)
          : null,
      quality: json['quality'] != null
          ? MediaQuality.fromJson(json['quality'] as Map<String, dynamic>)
          : null,
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => MediaLanguageInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFormats: (json['customFormats'] as List<dynamic>?)
          ?.map((e) => MediaCustomFormat.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFormatScore: json['customFormatScore'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (relativePath != null) 'relativePath': relativePath,
      if (path != null) 'path': path,
      'size': size,
      'dateAdded': dateAdded.toIso8601String(),
      if (mediaInfo != null) 'mediaInfo': mediaInfo!.toJson(),
      if (quality != null) 'quality': quality!.toJson(),
      if (languages != null)
        'languages': languages!.map((e) => e.toJson()).toList(),
      if (customFormats != null)
        'customFormats': customFormats!.map((e) => e.toJson()).toList(),
      if (customFormatScore != null) 'customFormatScore': customFormatScore,
    };
  }

  @override
  List<Object?> get props => [
    id,
    relativePath,
    path,
    size,
    dateAdded,
    mediaInfo,
    quality,
    languages,
    customFormats,
    customFormatScore,
  ];
}

class FileMediaInfo extends Equatable {
  final int? audioBitrate;
  final int? audioStreamCount;
  final double? audioChannels;
  final String? audioCodec;
  final String? audioLanguages;

  final int? videoBitDepth;
  final int? videoBitrate;
  final double? videoFps;
  final String? videoCodec;
  final String? resolution;
  final String? runTime;
  final String? videoDynamicRange;
  final String? videoDynamicRangeType;
  final String? scanType;
  final String? subtitles;

  const FileMediaInfo({
    this.audioBitrate,
    this.audioStreamCount,
    this.audioChannels,
    this.audioCodec,
    this.audioLanguages,
    this.videoBitDepth,
    this.videoBitrate,
    this.videoFps,
    this.videoCodec,
    this.resolution,
    this.runTime,
    this.videoDynamicRange,
    this.videoDynamicRangeType,
    this.scanType,
    this.subtitles,
  });

  factory FileMediaInfo.fromJson(Map<String, dynamic> json) {
    return FileMediaInfo(
      audioBitrate: json['audioBitrate'] as int?,
      audioStreamCount: json['audioStreamCount'] as int?,
      audioChannels: (json['audioChannels'] as num?)?.toDouble(),
      audioCodec: json['audioCodec'] as String?,
      audioLanguages: json['audioLanguages'] as String?,
      videoBitDepth: json['videoBitDepth'] as int?,
      videoBitrate: json['videoBitrate'] as int?,
      videoFps: (json['videoFps'] as num?)?.toDouble(),
      videoCodec: json['videoCodec'] as String?,
      resolution: json['resolution'] as String?,
      runTime: json['runTime'] as String?,
      videoDynamicRange: json['videoDynamicRange'] as String?,
      videoDynamicRangeType: json['videoDynamicRangeType'] as String?,
      scanType: json['scanType'] as String?,
      subtitles: json['subtitles'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (audioBitrate != null) 'audioBitrate': audioBitrate,
      if (audioStreamCount != null) 'audioStreamCount': audioStreamCount,
      if (audioChannels != null) 'audioChannels': audioChannels,
      if (audioCodec != null) 'audioCodec': audioCodec,
      if (audioLanguages != null) 'audioLanguages': audioLanguages,
      if (videoBitDepth != null) 'videoBitDepth': videoBitDepth,
      if (videoBitrate != null) 'videoBitrate': videoBitrate,
      if (videoFps != null) 'videoFps': videoFps,
      if (videoCodec != null) 'videoCodec': videoCodec,
      if (resolution != null) 'resolution': resolution,
      if (runTime != null) 'runTime': runTime,
      if (videoDynamicRange != null) 'videoDynamicRange': videoDynamicRange,
      if (videoDynamicRangeType != null)
        'videoDynamicRangeType': videoDynamicRangeType,
      if (scanType != null) 'scanType': scanType,
      if (subtitles != null) 'subtitles': subtitles,
    };
  }

  @override
  List<Object?> get props => [
    audioBitrate,
    audioStreamCount,
    audioChannels,
    audioCodec,
    audioLanguages,
    videoBitDepth,
    videoBitrate,
    videoFps,
    videoCodec,
    resolution,
    runTime,
    videoDynamicRange,
    videoDynamicRangeType,
    scanType,
    subtitles,
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
