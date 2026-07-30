import 'package:equatable/equatable.dart';

import '../instance/instance.dart';
import '../movie/movie.dart';
import '../series/series.dart';
import '../shared/media_custom_format.dart';
import '../shared/media_file.dart';
import '../shared/media_language.dart';

/// Represents a paginated list of queue items.
class QueueItems extends Equatable {
  final int page;
  final int pageSize;
  final String sortKey;
  final String sortDirection;
  final int totalRecords;
  final List<QueueItem> records;

  const QueueItems({
    required this.page,
    required this.pageSize,
    required this.sortKey,
    required this.sortDirection,
    required this.totalRecords,
    required this.records,
  });

  factory QueueItems.fromJson(Map<String, dynamic> json) {
    return QueueItems(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      sortKey: json['sortKey'] as String? ?? '',
      sortDirection: json['sortDirection'] as String? ?? 'default',
      totalRecords: json['totalRecords'] as int? ?? 0,
      records:
          (json['records'] as List<dynamic>?)
              ?.map((e) => QueueItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    page,
    pageSize,
    sortKey,
    sortDirection,
    totalRecords,
    records,
  ];
}

/// Represents a single item in the activity queue.
class QueueItem extends Equatable {
  final int id;

  /// Identifier of the server that owns this queue item.
  final String? instanceId;

  /// Service type of the server that owns this queue item.
  final InstanceType? instanceType;
  final int? movieId;
  final int? seriesId;
  final int? episodeId;
  final int? seasonNumber;
  final String title;

  /// Indexer that supplied the download.
  final String? indexer;

  /// Date when the task entered the download queue.
  final DateTime? added;

  /// Quality selected for the queued release.
  final MediaQuality? quality;

  /// Languages associated with the queued release.
  final List<MediaLanguage> languages;

  /// Custom formats matched by the queued release.
  final List<MediaCustomFormat> customFormats;

  /// Aggregate custom format score for the queued release.
  final int? customFormatScore;
  final QueueStatus status;
  final String? trackedDownloadStatus;
  final String? trackedDownloadState;
  final List<QueueStatusMessage> statusMessages;
  final String? errorMessage;
  final String? downloadId;
  final String protocol;
  final String? downloadClient;
  final String? outputPath;
  final int? size;
  final int sizeleft;
  final DateTime? estimatedCompletionTime;
  final double? progress;
  final Movie? movie;
  final Series? series;
  final Episode? episode;

  /// Number of queue records represented by this task.
  final int taskGroupCount;

  const QueueItem({
    required this.id,
    this.instanceId,
    this.instanceType,
    this.movieId,
    this.seriesId,
    this.episodeId,
    this.seasonNumber,
    required this.title,
    this.indexer,
    this.added,
    this.quality,
    this.languages = const [],
    this.customFormats = const [],
    this.customFormatScore,
    required this.status,
    this.trackedDownloadStatus,
    this.trackedDownloadState,
    this.statusMessages = const [],
    this.errorMessage,
    this.downloadId,
    required this.protocol,
    this.downloadClient,
    this.outputPath,
    this.size,
    required this.sizeleft,
    this.estimatedCompletionTime,
    this.progress,
    this.movie,
    this.series,
    this.episode,
    this.taskGroupCount = 1,
  });

  /// Checks if the item has a warning status.
  bool get hasWarning =>
      trackedDownloadStatus == 'warning' || status == QueueStatus.warning;

  /// Checks if the item has a critical error.
  bool get hasError =>
      trackedDownloadStatus == 'error' ||
      status == QueueStatus.failed ||
      (errorMessage?.trim().isNotEmpty ?? false);

  /// Checks if the queue item needs user attention.
  bool get hasIssue => hasWarning || hasError;

  /// Checks if user intervention is required (e.g., manual import).
  bool get needsManualImport =>
      downloadId != null &&
      trackedDownloadStatus == 'warning' &&
      (trackedDownloadState == 'importPending' ||
          trackedDownloadState == 'importBlocked');

  /// Calculates the download percentage (0-100).
  double get progressPercent {
    if (progress != null) return progress!.clamp(0, 100);
    if (size == null || size == 0) return 0;
    return (((size! - sizeleft) / size!) * 100).clamp(0, 100);
  }

  /// Returns a display title based on the context (Movie, Series, or fallback).
  String get displayTitle {
    if (movie != null) return movie!.title;
    if (series != null && taskGroupCount > 1 && seasonNumber != null) {
      return '${series!.title} (Season $seasonNumber)';
    }
    if (series != null) return series!.title;
    return title;
  }

  /// Returns a human-readable quality name when available.
  String? get qualityLabel => quality?.quality.name;

  /// Returns all language names available for the queue item.
  String get languagesLabel {
    final names = languages
        .map((language) => language.name)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty);
    return names.isEmpty ? 'Unknown' : names.join(', ');
  }

  /// Returns all custom format names available for the queue item.
  String? get customFormatsLabel {
    if (customFormats.isEmpty) return null;
    return customFormats.map((format) => format.name).join(', ');
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: (json['id'] as num).toInt(),
      movieId: json['movieId'] as int?,
      seriesId: json['seriesId'] as int?,
      episodeId: json['episodeId'] as int?,
      seasonNumber: json['seasonNumber'] as int?,
      title: json['title'] as String? ?? '',
      indexer: json['indexer'] as String?,
      added: _parseDateTime(json['added']),
      quality: json['quality'] is Map<String, dynamic>
          ? MediaQuality.fromJson(json['quality'] as Map<String, dynamic>)
          : null,
      languages: _parseObjectList(json['languages'], MediaLanguage.fromJson),
      customFormats: _parseObjectList(
        json['customFormats'],
        MediaCustomFormat.fromJson,
      ),
      customFormatScore: (json['customFormatScore'] as num?)?.toInt(),
      status: QueueStatus.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == (json['status'] as String?)?.toLowerCase(),
        orElse: () => QueueStatus.unknown,
      ),
      trackedDownloadStatus: json['trackedDownloadStatus'] as String?,
      trackedDownloadState: json['trackedDownloadState'] as String?,
      statusMessages:
          (json['statusMessages'] as List<dynamic>?)
              ?.map(
                (e) => QueueStatusMessage.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      errorMessage: json['errorMessage'] as String?,
      downloadId: json['downloadId'] as String?,
      protocol: json['protocol'] as String? ?? 'unknown',
      downloadClient: json['downloadClient'] as String?,
      outputPath: json['outputPath'] as String?,
      size: (json['size'] as num?)?.round(),
      sizeleft: (json['sizeleft'] as num?)?.round() ?? 0,
      estimatedCompletionTime: _parseDateTime(json['estimatedCompletionTime']),
      progress: (json['progress'] as num?)?.toDouble(),
      movie: json['movie'] != null
          ? Movie.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
      series: json['series'] != null
          ? Series.fromJson(json['series'] as Map<String, dynamic>)
          : null,
      episode: json['episode'] != null
          ? Episode.fromJson(json['episode'] as Map<String, dynamic>)
          : null,
    );
  }

  QueueItem copyWith({
    String? instanceId,
    InstanceType? instanceType,
    int? taskGroupCount,
  }) {
    return QueueItem(
      id: id,
      instanceId: instanceId ?? this.instanceId,
      instanceType: instanceType ?? this.instanceType,
      movieId: movieId,
      seriesId: seriesId,
      episodeId: episodeId,
      seasonNumber: seasonNumber,
      title: title,
      indexer: indexer,
      added: added,
      quality: quality,
      languages: languages,
      customFormats: customFormats,
      customFormatScore: customFormatScore,
      status: status,
      trackedDownloadStatus: trackedDownloadStatus,
      trackedDownloadState: trackedDownloadState,
      statusMessages: statusMessages,
      errorMessage: errorMessage,
      downloadId: downloadId,
      protocol: protocol,
      downloadClient: downloadClient,
      outputPath: outputPath,
      size: size,
      sizeleft: sizeleft,
      estimatedCompletionTime: estimatedCompletionTime,
      progress: progress,
      movie: movie,
      series: series,
      episode: episode,
      taskGroupCount: taskGroupCount ?? this.taskGroupCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    instanceId,
    instanceType,
    movieId,
    seriesId,
    episodeId,
    seasonNumber,
    title,
    indexer,
    added,
    quality,
    languages,
    customFormats,
    customFormatScore,
    status,
    trackedDownloadStatus,
    trackedDownloadState,
    statusMessages,
    errorMessage,
    downloadId,
    protocol,
    downloadClient,
    outputPath,
    size,
    sizeleft,
    estimatedCompletionTime,
    progress,
    movie,
    series,
    episode,
    taskGroupCount,
  ];
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

List<T> _parseObjectList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List<dynamic>) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

/// Defines the current status of a queue item.
enum QueueStatus {
  unknown,
  queued,
  paused,
  downloading,
  completed,
  failed,
  warning,
  delay;

  String get label {
    switch (this) {
      case QueueStatus.unknown:
        return 'Unknown';
      case QueueStatus.queued:
        return 'Queued';
      case QueueStatus.paused:
        return 'Paused';
      case QueueStatus.downloading:
        return 'Downloading';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.failed:
        return 'Failed';
      case QueueStatus.warning:
        return 'Warning';
      case QueueStatus.delay:
        return 'Pending';
    }
  }
}

/// Contains messages related to the queue item status (e.g., failure reasons).
class QueueStatusMessage extends Equatable {
  final String? title;
  final List<String> messages;

  const QueueStatusMessage({this.title, this.messages = const []});

  factory QueueStatusMessage.fromJson(Map<String, dynamic> json) {
    return QueueStatusMessage(
      title: json['title'] as String?,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [title, messages];
}
