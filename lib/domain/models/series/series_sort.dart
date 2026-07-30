import 'package:arrmate/domain/models/series/series.dart';
import 'package:equatable/equatable.dart';

/// Encapsulates sorting and filtering options for series lists.
class SeriesSort extends Equatable {
  final SeriesSortOption option;
  final bool isAscending;
  final SeriesFilter filter;
  final String? rootFolderPath;

  const SeriesSort({
    this.option = SeriesSortOption.byAdded,
    this.isAscending = false,
    this.filter = SeriesFilter.all,
    this.rootFolderPath,
  });

  SeriesSort copyWith({
    SeriesSortOption? option,
    bool? isAscending,
    SeriesFilter? filter,
    String? rootFolderPath,
    bool clearRootFolderPath = false,
  }) {
    return SeriesSort(
      option: option ?? this.option,
      isAscending: isAscending ?? this.isAscending,
      filter: filter ?? this.filter,
      rootFolderPath: clearRootFolderPath
          ? null
          : rootFolderPath ?? this.rootFolderPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option': option.name,
      'isAscending': isAscending,
      'filter': filter.name,
      if (rootFolderPath != null) 'rootFolderPath': rootFolderPath,
    };
  }

  factory SeriesSort.fromJson(Map<String, dynamic> json) {
    final optionName = json['option'] == 'byAiring'
        ? SeriesSortOption.byNextAiring.name
        : json['option'];
    return SeriesSort(
      option: SeriesSortOption.values.firstWhere(
        (e) => e.name == optionName,
        orElse: () => SeriesSortOption.byAdded,
      ),
      isAscending: json['isAscending'] as bool? ?? false,
      filter: SeriesFilter.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => SeriesFilter.all,
      ),
      rootFolderPath: _readRootFolderPath(json),
    );
  }

  /// Returns whether [series] matches the selected filter and root folder.
  bool matches(Series series) {
    if (!_matchesRootFolder(series.rootFolderPath)) return false;
    return filter.filter(series);
  }

  bool _matchesRootFolder(String? seriesRootFolderPath) {
    if (rootFolderPath == null) return true;
    if (seriesRootFolderPath == null) return false;
    return _normalizePath(rootFolderPath!) ==
        _normalizePath(seriesRootFolderPath);
  }

  @override
  List<Object?> get props => [option, isAscending, filter, rootFolderPath];
}

/// Available options for sorting series.
enum SeriesSortOption {
  byTitle,
  byYear,
  byAdded,
  byRating,
  bySize,
  byNextAiring,
  byPreviousAiring;

  String get label {
    switch (this) {
      case SeriesSortOption.byTitle:
        return 'Title';
      case SeriesSortOption.byYear:
        return 'Year';
      case SeriesSortOption.byAdded:
        return 'Added';
      case SeriesSortOption.byRating:
        return 'Rating';
      case SeriesSortOption.bySize:
        return 'Size';
      case SeriesSortOption.byNextAiring:
        return 'Next Airing';
      case SeriesSortOption.byPreviousAiring:
        return 'Previous Airing';
    }
  }

  int compare(Series a, Series b) {
    switch (this) {
      case SeriesSortOption.byTitle:
        return a.sortTitle.compareTo(b.sortTitle);
      case SeriesSortOption.byYear:
        return a.year.compareTo(b.year);
      case SeriesSortOption.byAdded:
        return a.added.compareTo(b.added);
      case SeriesSortOption.byRating:
        return (a.ratings?.value ?? 0).compareTo(b.ratings?.value ?? 0);
      case SeriesSortOption.bySize:
        return (a.statistics?.sizeOnDisk ?? 0).compareTo(
          b.statistics?.sizeOnDisk ?? 0,
        );
      case SeriesSortOption.byNextAiring:
        return _compareNullableDateTimeReversed(a.nextAiring, b.nextAiring);
      case SeriesSortOption.byPreviousAiring:
        return _compareNullableDateTime(a.previousAiring, b.previousAiring);
    }
  }
}

/// Available filters for series lists.
enum SeriesFilter {
  all,
  monitored,
  unmonitored,
  ended,
  continuing,
  missing,
  dangling;

  String get label {
    switch (this) {
      case SeriesFilter.all:
        return 'All Series';
      case SeriesFilter.monitored:
        return 'Monitored';
      case SeriesFilter.unmonitored:
        return 'Unmonitored';
      case SeriesFilter.ended:
        return 'Ended';
      case SeriesFilter.continuing:
        return 'Continuing';
      case SeriesFilter.missing:
        return 'Missing';
      case SeriesFilter.dangling:
        return 'Dangling';
    }
  }

  bool filter(Series series) {
    switch (this) {
      case SeriesFilter.all:
        return true;
      case SeriesFilter.monitored:
        return series.monitored;
      case SeriesFilter.unmonitored:
        return !series.monitored;
      case SeriesFilter.ended:
        return series.status == SeriesStatus.ended;
      case SeriesFilter.continuing:
        return series.status == SeriesStatus.continuing;
      case SeriesFilter.missing:
        return series.episodeCount > series.episodeFileCount;
      case SeriesFilter.dangling:
        return !series.monitored && series.episodeCount == 0;
    }
  }
}

String? _readRootFolderPath(Map<String, dynamic> json) {
  final value = json['rootFolderPath'] ?? json['folder'];
  if (value is! String || value.isEmpty || value == 'all') return null;
  return value;
}

String _normalizePath(String path) {
  return path.replaceFirst(RegExp(r'[/\\]+$'), '');
}

int _compareNullableDateTime(DateTime? a, DateTime? b) {
  if (a == null) return b == null ? 0 : -1;
  if (b == null) return 1;
  return a.compareTo(b);
}

int _compareNullableDateTimeReversed(DateTime? a, DateTime? b) {
  if (a == null) return b == null ? 0 : -1;
  if (b == null) return 1;
  return b.compareTo(a);
}
