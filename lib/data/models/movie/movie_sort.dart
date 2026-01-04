import 'package:arrmate/data/models/movie/movie.dart';

class MovieSort {
  final MovieSortOption option;
  final bool isAscending;
  final MovieFilter filter;

  const MovieSort({
    this.option = MovieSortOption.byAdded,
    this.isAscending = false,
    this.filter = MovieFilter.all,
  });

  MovieSort copyWith({
    MovieSortOption? option,
    bool? isAscending,
    MovieFilter? filter,
  }) {
    return MovieSort(
      option: option ?? this.option,
      isAscending: isAscending ?? this.isAscending,
      filter: filter ?? this.filter,
    );
  }
}

enum MovieSortOption {
  byTitle,
  byYear,
  byAdded,
  byRating,
  bySize,
  byRuntime;

  String get label {
    switch (this) {
      case MovieSortOption.byTitle: return 'Title';
      case MovieSortOption.byYear: return 'Year';
      case MovieSortOption.byAdded: return 'Added';
      case MovieSortOption.byRating: return 'Rating';
      case MovieSortOption.bySize: return 'Size';
      case MovieSortOption.byRuntime: return 'Runtime';
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
    }
  }
}

enum MovieFilter {
  all,
  monitored,
  unmonitored,
  missing,
  downloaded;

  String get label {
    switch (this) {
      case MovieFilter.all: return 'All Movies';
      case MovieFilter.monitored: return 'Monitored';
      case MovieFilter.unmonitored: return 'Unmonitored';
      case MovieFilter.missing: return 'Missing';
      case MovieFilter.downloaded: return 'Downloaded';
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
    }
  }
}
