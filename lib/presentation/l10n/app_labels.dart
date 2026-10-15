import '../../core/l10n/app_locale.dart';
import '../../core/utils/discovery_results.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../screens/calendar/providers/calendar_provider.dart';
import '../theme/app_theme.dart';

/// Localized labels for [DiscoverySortOption].
extension DiscoverySortOptionL10n on DiscoverySortOption {
  /// Returns the translated [DiscoverySortOption.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    DiscoverySortOption.relevance => l10n.labelDiscoverySortRelevant,
    DiscoverySortOption.latest => l10n.labelDiscoverySortLatest,
    DiscoverySortOption.rating => l10n.labelSortRating,
  };
}

/// Localized labels for [AppColorScheme].
extension AppColorSchemeL10n on AppColorScheme {
  /// Returns the translated [AppColorScheme.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AppColorScheme.blue => l10n.labelColorBlue,
    AppColorScheme.indigo => l10n.labelColorIndigo,
    AppColorScheme.purple => l10n.labelColorPurple,
    AppColorScheme.pink => l10n.labelColorPink,
    AppColorScheme.red => l10n.labelColorRed,
    AppColorScheme.orange => l10n.labelColorOrange,
    AppColorScheme.amber => l10n.labelColorAmber,
    AppColorScheme.green => l10n.labelColorGreen,
    AppColorScheme.teal => l10n.labelColorTeal,
  };
}

/// Localized labels for [AppAppearance].
extension AppAppearanceL10n on AppAppearance {
  /// Returns the translated [AppAppearance.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AppAppearance.system => l10n.labelAppearanceSystem,
    AppAppearance.light => l10n.labelAppearanceLight,
    AppAppearance.dark => l10n.labelAppearanceDark,
  };
}

/// Localized labels for [AppTab].
extension AppTabL10n on AppTab {
  /// Returns the translated navigation [AppTab.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AppTab.movies => l10n.commonMovies,
    AppTab.series => l10n.commonSeries,
    AppTab.calendar => l10n.labelTabCalendar,
    AppTab.activity => l10n.labelTabActivity,
    AppTab.settings => l10n.labelTabSettings,
  };
}

/// Localized labels for [ViewMode].
extension ViewModeL10n on ViewMode {
  /// Returns the translated [ViewMode.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ViewMode.grid => l10n.labelViewModeGrid,
    ViewMode.list => l10n.labelViewModeList,
  };
}

/// Localized labels for [CalendarEventType].
extension CalendarEventTypeL10n on CalendarEventType {
  /// Returns the translated [CalendarEventType.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    CalendarEventType.cinema => l10n.labelInCinemas,
    CalendarEventType.digital => l10n.labelDigitalRelease,
    CalendarEventType.physical => l10n.labelPhysicalRelease,
    CalendarEventType.episode => l10n.labelEpisode,
  };
}

/// Localized labels for [CalendarMediaType].
extension CalendarMediaTypeL10n on CalendarMediaType {
  /// Returns the translated [CalendarMediaType.label].
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    CalendarMediaType.all => l10n.labelCalendarAllMedia,
    CalendarMediaType.movies => l10n.commonMovies,
    CalendarMediaType.series => l10n.commonSeries,
  };
}

/// Localized labels for [CalendarEvent].
extension CalendarEventL10n on CalendarEvent {
  /// Returns the translated [CalendarEvent.title].
  String localizedTitle(AppLocalizations l10n) => isMovie
      ? movie?.title ?? l10n.labelCalendarUnknownMovie
      : series?.title ?? l10n.labelCalendarUnknownSeries;

  /// Returns the translated [CalendarEvent.subtitle].
  String localizedSubtitle(AppLocalizations l10n) {
    if (isEpisode) {
      final seasonNumber = episode?.seasonNumber ?? 0;
      final episodeNumber = episode?.episodeNumber ?? 0;
      final episodeTitle = episode?.title ?? l10n.labelTba;
      return '${seasonNumber}x${episodeNumber.toString().padLeft(2, '0')} - '
          '$episodeTitle';
    }

    final year = movie?.year ?? 0;
    final typeLabel = type.localizedLabel(l10n);
    return year > 0 ? '$year · $typeLabel' : typeLabel;
  }
}
