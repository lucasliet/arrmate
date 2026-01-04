import 'package:arrmate/data/models/series/series.dart';

class SeriesSort {
  final SeriesSortOption option;
  final bool isAscending;
  final SeriesFilter filter;

  const SeriesSort({
    this.option = SeriesSortOption.byAdded,
    this.isAscending = false,
    this.filter = SeriesFilter.all,
  });

  SeriesSort copyWith({
    SeriesSortOption? option,
    bool? isAscending,
    SeriesFilter? filter,
  }) {
    return SeriesSort(
      option: option ?? this.option,
      isAscending: isAscending ?? this.isAscending,
      filter: filter ?? this.filter,
    );
  }
}

enum SeriesSortOption {
  byTitle,
  byYear,
  byAdded,
  byRating,
  bySize;

  String get label {
    switch (this) {
      case SeriesSortOption.byTitle: return 'Title';
      case SeriesSortOption.byYear: return 'Year';
      case SeriesSortOption.byAdded: return 'Added';
      case SeriesSortOption.byRating: return 'Rating';
      case SeriesSortOption.bySize: return 'Size';
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
        return (a.statistics?.sizeOnDisk ?? 0).compareTo(b.statistics?.sizeOnDisk ?? 0);
    }
  }
}

enum SeriesFilter {
  all,
  monitored,
  unmonitored,
  ended,
  continuing;

  String get label {
    switch (this) {
      case SeriesFilter.all: return 'All Series';
      case SeriesFilter.monitored: return 'Monitored';
      case SeriesFilter.unmonitored: return 'Unmonitored';
      case SeriesFilter.ended: return 'Ended';
      case SeriesFilter.continuing: return 'Continuing';
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
    }
  }
}
