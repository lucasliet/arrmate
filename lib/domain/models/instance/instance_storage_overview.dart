import 'package:equatable/equatable.dart';

import '../movie/movie.dart';
import '../series/series.dart';
import 'instance.dart';

/// Represents a storage location reported by an Arr instance.
class InstanceDiskSpace extends Equatable {
  /// Filesystem path associated with this storage location.
  final String path;

  /// Optional human-readable label supplied by the server.
  final String? label;

  /// Available bytes in this storage location.
  final int freeSpace;

  /// Total bytes in this storage location.
  final int totalSpace;

  const InstanceDiskSpace({
    required this.path,
    required this.freeSpace,
    required this.totalSpace,
    this.label,
  });

  /// Creates storage information from a Radarr or Sonarr API response.
  factory InstanceDiskSpace.fromJson(Map<String, dynamic> json) {
    return InstanceDiskSpace(
      path: json['path'] as String? ?? '',
      label: json['label'] as String?,
      freeSpace: (json['freeSpace'] as num?)?.toInt() ?? 0,
      totalSpace: (json['totalSpace'] as num?)?.toInt() ?? 0,
    );
  }

  /// Human-readable name for the storage location.
  String get displayLabel {
    final trimmedLabel = label?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      return trimmedLabel;
    }

    final trimmedPath = path.replaceFirst(RegExp(r'/+$'), '');
    return trimmedPath.isEmpty ? path : trimmedPath;
  }

  /// Bytes currently used in this storage location.
  int get usedSpace {
    final used = totalSpace - freeSpace;
    return used > 0 ? used : 0;
  }

  /// Fraction of total storage currently used.
  double get usedFraction {
    if (totalSpace <= 0) {
      return 0;
    }
    return (usedSpace / totalSpace).clamp(0, 1).toDouble();
  }

  @override
  List<Object?> get props => [path, label, freeSpace, totalSpace];
}

/// Summarizes the media library stored by an instance.
class InstanceLibraryStatistics extends Equatable {
  /// Number of movies in a Radarr library.
  final int movieCount;

  /// Number of series in a Sonarr library.
  final int seriesCount;

  /// Number of downloaded episode files in a Sonarr library.
  final int episodeCount;

  /// Total bytes occupied by the media library.
  final int sizeOnDisk;

  const InstanceLibraryStatistics({
    this.movieCount = 0,
    this.seriesCount = 0,
    this.episodeCount = 0,
    this.sizeOnDisk = 0,
  });

  /// Calculates library statistics from Radarr movies.
  factory InstanceLibraryStatistics.fromMovies(List<Movie> movies) {
    return InstanceLibraryStatistics(
      movieCount: movies.length,
      sizeOnDisk: movies.fold(
        0,
        (total, movie) => total + (movie.sizeOnDisk ?? 0),
      ),
    );
  }

  /// Calculates library statistics from Sonarr series.
  factory InstanceLibraryStatistics.fromSeries(List<Series> series) {
    return InstanceLibraryStatistics(
      seriesCount: series.length,
      episodeCount: series.fold(
        0,
        (total, item) => total + item.episodeFileCount,
      ),
      sizeOnDisk: series.fold(
        0,
        (total, item) => total + (item.statistics?.sizeOnDisk ?? 0),
      ),
    );
  }

  @override
  List<Object?> get props => [
    movieCount,
    seriesCount,
    episodeCount,
    sizeOnDisk,
  ];
}

/// Identifies a section that failed while loading an instance overview.
enum InstanceOverviewSection {
  /// Version and server status metadata.
  status,

  /// Media library counts and size.
  library,

  /// Storage locations exposed by the disk space endpoint.
  diskSpace,
}

/// Describes an unavailable section of an instance overview.
class InstanceOverviewFailure extends Equatable {
  /// Section that could not be loaded.
  final InstanceOverviewSection section;

  /// User-facing description of the failure.
  final String message;

  const InstanceOverviewFailure({required this.section, required this.message});

  @override
  List<Object?> get props => [section, message];
}

/// Contains the independently loaded system information for one instance.
class InstanceStorageOverview extends Equatable {
  /// Configured instance represented by this overview.
  final Instance instance;

  /// Live status when available.
  final InstanceStatus? status;

  /// Media library statistics when available.
  final InstanceLibraryStatistics? library;

  /// Storage locations when available.
  final List<InstanceDiskSpace>? diskSpaces;

  /// Sections that failed without preventing other data from loading.
  final List<InstanceOverviewFailure> failures;

  const InstanceStorageOverview({
    required this.instance,
    this.status,
    this.library,
    this.diskSpaces,
    this.failures = const [],
  });

  /// Best available server version.
  String? get version => status?.version ?? instance.version;

  /// Whether at least one overview section failed to load.
  bool get hasFailures => failures.isNotEmpty;

  @override
  List<Object?> get props => [instance, status, library, diskSpaces, failures];
}
