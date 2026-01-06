import 'package:equatable/equatable.dart';

import '../movie/movie.dart';
import '../series/series.dart';

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
  final String? instanceId;
  final int? movieId;
  final int? seriesId;
  final int? episodeId;
  final int? seasonNumber;
  final String title;
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

  const QueueItem({
    required this.id,
    this.instanceId,
    this.movieId,
    this.seriesId,
    this.episodeId,
    this.seasonNumber,
    required this.title,
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
  });

  /// Checks if the item has a warning status.
  bool get hasWarning => trackedDownloadStatus == 'warning';

  /// Checks if the item has a critical error.
  bool get hasError => trackedDownloadStatus == 'error' || errorMessage != null;

  /// Checks if user intervention is required (e.g., manual import).
  bool get needsManualImport =>
      downloadId != null &&
      trackedDownloadStatus == 'warning' &&
      (trackedDownloadState == 'importPending' ||
          trackedDownloadState == 'importBlocked');

  /// Calculates the download percentage (0-100).
  double get progressPercent {
    if (progress != null) return progress!;
    if (size == null || size == 0) return 0;
    return ((size! - sizeleft) / size!) * 100;
  }

  /// Returns a display title based on the context (Movie, Series, or fallback).
  String get displayTitle {
    if (movie != null) return movie!.title;
    if (series != null) return series!.title;
    return title;
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as int,
      movieId: json['movieId'] as int?,
      seriesId: json['seriesId'] as int?,
      episodeId: json['episodeId'] as int?,
      seasonNumber: json['seasonNumber'] as int?,
      title: json['title'] as String? ?? '',
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
      size: json['size'] as int?,
      sizeleft: json['sizeleft'] as int? ?? 0,
      estimatedCompletionTime: json['estimatedCompletionTime'] != null
          ? DateTime.tryParse(json['estimatedCompletionTime'] as String)
          : null,
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

  QueueItem copyWith({String? instanceId}) {
    return QueueItem(
      id: id,
      instanceId: instanceId ?? this.instanceId,
      movieId: movieId,
      seriesId: seriesId,
      episodeId: episodeId,
      seasonNumber: seasonNumber,
      title: title,
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
    );
  }

  @override
  List<Object?> get props => [
    id,
    instanceId,
    movieId,
    seriesId,
    episodeId,
    seasonNumber,
    title,
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
  ];
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
