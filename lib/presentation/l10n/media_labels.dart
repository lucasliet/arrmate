import '../../core/l10n/app_locale.dart';
import '../../domain/models/models.dart';

/// Localized labels for [MovieStatus].
extension MovieStatusL10n on MovieStatus {
  /// Returns the translated [MovieStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MovieStatus.tba => l10n.labelMovieStatusTba,
    MovieStatus.announced => l10n.labelMovieStatusAnnounced,
    MovieStatus.inCinemas => l10n.labelInCinemas,
    MovieStatus.released => l10n.labelMovieStatusReleased,
    MovieStatus.deleted => l10n.labelDeleted,
  };
}

/// Localized labels for [Movie].
extension MovieL10n on Movie {
  /// Returns the translated [Movie.stateLabel].
  String localizedStateLabel(AppLocalizations l10n) {
    if (isDownloaded) return l10n.labelDownloaded;
    if (isWaiting) {
      if (status == MovieStatus.tba || status == MovieStatus.announced) {
        return l10n.labelMovieStateUnreleased;
      }
      return l10n.labelMovieStateWaiting;
    }
    if (monitored && isAvailable) return l10n.labelMissing;
    return l10n.labelMovieStateUnwanted;
  }

  /// Returns the translated [Movie.yearLabel] (the year, or "TBA").
  String localizedYearLabel(AppLocalizations l10n) =>
      year > 0 ? '$year' : l10n.labelTba;
}

/// Localized labels for [MovieMonitorType].
extension MovieMonitorTypeL10n on MovieMonitorType {
  /// Returns the translated [MovieMonitorType.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MovieMonitorType.movieOnly => l10n.labelMovieMonitorMovieOnly,
    MovieMonitorType.movieAndCollection =>
      l10n.labelMovieMonitorMovieAndCollection,
    MovieMonitorType.none => l10n.labelNone,
  };
}

/// Localized labels for [MovieSortOption].
extension MovieSortOptionL10n on MovieSortOption {
  /// Returns the translated [MovieSortOption.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MovieSortOption.byTitle => l10n.labelSortTitle,
    MovieSortOption.byYear => l10n.labelSortYear,
    MovieSortOption.byAdded => l10n.labelSortAdded,
    MovieSortOption.byRating => l10n.labelSortRating,
    MovieSortOption.bySize => l10n.commonSize,
    MovieSortOption.byRuntime => l10n.labelSortRuntime,
    MovieSortOption.byGrabbed => l10n.labelGrabbed,
    MovieSortOption.byRelease => l10n.labelDigitalRelease,
  };
}

/// Localized labels for [MovieFilter].
extension MovieFilterL10n on MovieFilter {
  /// Returns the translated [MovieFilter.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MovieFilter.all => l10n.labelFilterAllMovies,
    MovieFilter.monitored => l10n.commonMonitored,
    MovieFilter.unmonitored => l10n.commonUnmonitored,
    MovieFilter.missing => l10n.labelMissing,
    MovieFilter.downloaded => l10n.labelDownloaded,
    MovieFilter.wanted => l10n.labelWanted,
    MovieFilter.dangling => l10n.labelDangling,
  };
}

/// Localized labels for [Series].
extension SeriesL10n on Series {
  /// Returns the translated [Series.yearLabel] (the year, or "TBA").
  String localizedYearLabel(AppLocalizations l10n) =>
      year > 0 ? '$year' : l10n.labelTba;
}

/// Localized labels for [Episode].
extension EpisodeL10n on Episode {
  /// Returns the translated [Episode.fullLabel] (`SxxEyy - Title`, with a
  /// translated "TBA" when the title is unknown).
  String localizedFullLabel(AppLocalizations l10n) =>
      '$episodeLabel - ${title ?? l10n.labelTba}';
}

/// Localized labels for [Season].
extension SeasonL10n on Season {
  /// Returns the translated [Season.label] ("Specials" or "Season N").
  String localizedLabel(AppLocalizations l10n) =>
      seasonNumber == 0 ? l10n.labelSpecials : l10n.formatSeason(seasonNumber);
}

/// Localized labels for [SeriesStatus].
extension SeriesStatusL10n on SeriesStatus {
  /// Returns the translated [SeriesStatus.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SeriesStatus.continuing => l10n.labelSeriesStatusContinuing,
    SeriesStatus.ended => l10n.labelSeriesStatusEnded,
    SeriesStatus.upcoming => l10n.labelSeriesStatusUpcoming,
    SeriesStatus.deleted => l10n.labelDeleted,
  };
}

/// Localized labels for [SeriesType].
extension SeriesTypeL10n on SeriesType {
  /// Returns the translated [SeriesType.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SeriesType.standard => l10n.labelSeriesTypeStandard,
    SeriesType.daily => l10n.labelSeriesTypeDaily,
    SeriesType.anime => l10n.labelSeriesTypeAnime,
  };
}

/// Localized labels for [SeriesMonitorType].
extension SeriesMonitorTypeL10n on SeriesMonitorType {
  /// Returns the translated [SeriesMonitorType.label].
  ///
  /// [SeriesMonitorType.skip] keeps its empty label.
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SeriesMonitorType.unknown => l10n.commonUnknown,
    SeriesMonitorType.all => l10n.labelSeriesMonitorAll,
    SeriesMonitorType.future => l10n.labelSeriesMonitorFuture,
    SeriesMonitorType.missing => l10n.labelSeriesMonitorMissing,
    SeriesMonitorType.existing => l10n.labelSeriesMonitorExisting,
    SeriesMonitorType.recent => l10n.labelSeriesMonitorRecent,
    SeriesMonitorType.pilot => l10n.labelSeriesMonitorPilot,
    SeriesMonitorType.firstSeason => l10n.labelSeriesMonitorFirstSeason,
    SeriesMonitorType.lastSeason => l10n.labelSeriesMonitorLastSeason,
    SeriesMonitorType.monitorSpecials => l10n.labelSeriesMonitorSpecials,
    SeriesMonitorType.unmonitorSpecials => l10n.labelSeriesUnmonitorSpecials,
    SeriesMonitorType.none => l10n.labelNone,
    SeriesMonitorType.skip => '',
  };
}

/// Localized labels for [SeriesSortOption].
extension SeriesSortOptionL10n on SeriesSortOption {
  /// Returns the translated [SeriesSortOption.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SeriesSortOption.byTitle => l10n.labelSortTitle,
    SeriesSortOption.byYear => l10n.labelSortYear,
    SeriesSortOption.byAdded => l10n.labelSortAdded,
    SeriesSortOption.byRating => l10n.labelSortRating,
    SeriesSortOption.bySize => l10n.commonSize,
    SeriesSortOption.byNextAiring => l10n.labelSortNextAiring,
    SeriesSortOption.byPreviousAiring => l10n.labelSortPreviousAiring,
  };
}

/// Localized labels for [SeriesFilter].
extension SeriesFilterL10n on SeriesFilter {
  /// Returns the translated [SeriesFilter.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SeriesFilter.all => l10n.labelFilterAllSeries,
    SeriesFilter.monitored => l10n.commonMonitored,
    SeriesFilter.unmonitored => l10n.commonUnmonitored,
    SeriesFilter.ended => l10n.labelSeriesStatusEnded,
    SeriesFilter.continuing => l10n.labelSeriesStatusContinuing,
    SeriesFilter.missing => l10n.labelMissing,
    SeriesFilter.dangling => l10n.labelDangling,
  };
}
