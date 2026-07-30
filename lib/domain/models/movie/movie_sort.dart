import 'package:arrmate/domain/models/movie/movie.dart';
import 'package:equatable/equatable.dart';

/// Encapsulates sorting and filtering options for movie lists.
class MovieSort extends Equatable {
  final MovieSortOption option;
  final bool isAscending;
  final MovieFilter filter;
  final String? rootFolderPath;

  const MovieSort({
    this.option = MovieSortOption.byAdded,
    this.isAscending = false,
    this.filter = MovieFilter.all,
    this.rootFolderPath,
  });

  MovieSort copyWith({
    MovieSortOption? option,
    bool? isAscending,
    MovieFilter? filter,
    String? rootFolderPath,
    bool clearRootFolderPath = false,
  }) {
    return MovieSort(
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

  factory MovieSort.fromJson(Map<String, dynamic> json) {
    return MovieSort(
      option: MovieSortOption.values.firstWhere(
        (e) => e.name == json['option'],
        orElse: () => MovieSortOption.byAdded,
      ),
      isAscending: json['isAscending'] as bool? ?? false,
      filter: MovieFilter.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => MovieFilter.all,
      ),
      rootFolderPath: _readRootFolderPath(json),
    );
  }

  /// Returns whether [movie] matches the selected filter and root folder.
  bool matches(Movie movie) {
    if (!_matchesRootFolder(movie.rootFolderPath)) return false;
    return filter.filter(movie);
  }

  bool _matchesRootFolder(String? movieRootFolderPath) {
    if (rootFolderPath == null) return true;
    if (movieRootFolderPath == null) return false;
    return _normalizePath(rootFolderPath!) ==
        _normalizePath(movieRootFolderPath);
  }

  @override
  List<Object?> get props => [option, isAscending, filter, rootFolderPath];
}

/// Available options for sorting movies.
enum MovieSortOption {
  byTitle,
  byYear,
  byAdded,
  byRating,
  bySize,
  byRuntime,
  byGrabbed,
  byRelease;

  String get label {
    switch (this) {
      case MovieSortOption.byTitle:
        return 'Title';
      case MovieSortOption.byYear:
        return 'Year';
      case MovieSortOption.byAdded:
        return 'Added';
      case MovieSortOption.byRating:
        return 'Rating';
      case MovieSortOption.bySize:
        return 'Size';
      case MovieSortOption.byRuntime:
        return 'Runtime';
      case MovieSortOption.byGrabbed:
        return 'Grabbed';
      case MovieSortOption.byRelease:
        return 'Digital Release';
    }
  }

  int compare(Movie a, Movie b) {
    switch (this) {
      case MovieSortOption.byTitle:
        return a.sortTitle.compareTo(b.sortTitle);
      case MovieSortOption.byYear:
        return a.year.compareTo(b.year);
      case MovieSortOption.byAdded:
        return a.added.compareTo(b.added);
      case MovieSortOption.byRating:
        return a.ratingScore.compareTo(b.ratingScore);
      case MovieSortOption.bySize:
        return (a.sizeOnDisk ?? 0).compareTo(b.sizeOnDisk ?? 0);
      case MovieSortOption.byRuntime:
        return a.runtime.compareTo(b.runtime);
      case MovieSortOption.byGrabbed:
        return _compareNullableDateTime(
          a.movieFile?.dateAdded,
          b.movieFile?.dateAdded,
        );
      case MovieSortOption.byRelease:
        return _compareNullableDateTime(a.digitalRelease, b.digitalRelease);
    }
  }
}

/// Available filters for movie lists.
enum MovieFilter {
  all,
  monitored,
  unmonitored,
  missing,
  downloaded,
  wanted,
  dangling;

  String get label {
    switch (this) {
      case MovieFilter.all:
        return 'All Movies';
      case MovieFilter.monitored:
        return 'Monitored';
      case MovieFilter.unmonitored:
        return 'Unmonitored';
      case MovieFilter.missing:
        return 'Missing';
      case MovieFilter.downloaded:
        return 'Downloaded';
      case MovieFilter.wanted:
        return 'Wanted';
      case MovieFilter.dangling:
        return 'Dangling';
    }
  }

  bool filter(Movie movie) {
    switch (this) {
      case MovieFilter.all:
        return true;
      case MovieFilter.monitored:
        return movie.monitored;
      case MovieFilter.unmonitored:
        return !movie.monitored;
      case MovieFilter.missing:
        return movie.monitored && !movie.isDownloaded && movie.isAvailable;
      case MovieFilter.downloaded:
        return movie.isDownloaded;
      case MovieFilter.wanted:
        return movie.monitored && !movie.isDownloaded;
      case MovieFilter.dangling:
        return !movie.monitored && !movie.isDownloaded;
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
