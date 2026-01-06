import 'package:arrmate/domain/models/series/series.dart';
import 'package:equatable/equatable.dart';

/// Encapsulates sorting and filtering options for series lists.
class SeriesSort extends Equatable {
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

  Map<String, dynamic> toJson() {
    return {
      'option': option.name,
      'isAscending': isAscending,
      'filter': filter.name,
    };
  }

  factory SeriesSort.fromJson(Map<String, dynamic> json) {
    return SeriesSort(
      option: SeriesSortOption.values.firstWhere(
        (e) => e.name == json['option'],
        orElse: () => SeriesSortOption.byAdded,
      ),
      isAscending: json['isAscending'] as bool? ?? false,
      filter: SeriesFilter.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => SeriesFilter.all,
      ),
    );
  }

  @override
  List<Object?> get props => [option, isAscending, filter];
}

/// Available options for sorting series.
enum SeriesSortOption {
  byTitle,
  byYear,
  byAdded,
  byRating,
  bySize;

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
    }
  }
}

/// Available filters for series lists.
enum SeriesFilter {
  all,
  monitored,
  unmonitored,
  ended,
  continuing;

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
