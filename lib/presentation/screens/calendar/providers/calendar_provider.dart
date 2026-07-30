import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';

/// Defines the type of release or airing for a calendar event.
enum CalendarEventType {
  /// Movie theatrical release.
  cinema,

  /// Movie digital release.
  digital,

  /// Movie physical release.
  physical,

  /// TV series episode airing.
  episode;

  /// Returns the display label for this event type.
  String get label {
    switch (this) {
      case CalendarEventType.cinema:
        return 'In Cinemas';
      case CalendarEventType.digital:
        return 'Digital Release';
      case CalendarEventType.physical:
        return 'Physical Release';
      case CalendarEventType.episode:
        return 'Episode';
    }
  }

  /// Returns the icon for this event type.
  IconData get icon {
    switch (this) {
      case CalendarEventType.cinema:
        return Icons.theaters;
      case CalendarEventType.digital:
        return Icons.play_circle_outline;
      case CalendarEventType.physical:
        return Icons.album;
      case CalendarEventType.episode:
        return Icons.tv;
    }
  }

  /// Returns the color for this event type based on theme brightness.
  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case CalendarEventType.cinema:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      case CalendarEventType.digital:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      case CalendarEventType.physical:
        return isDark ? Colors.teal.shade300 : Colors.teal.shade700;
      case CalendarEventType.episode:
        return isDark ? Colors.purple.shade300 : Colors.purple.shade700;
    }
  }

  /// Priority order for sorting events on the same date.
  int get sortPriority {
    switch (this) {
      case CalendarEventType.cinema:
        return 0;
      case CalendarEventType.digital:
        return 1;
      case CalendarEventType.physical:
        return 2;
      case CalendarEventType.episode:
        return 3;
    }
  }
}

/// Defines which media type is displayed in the calendar.
enum CalendarMediaType {
  /// Displays movies and episodes.
  all,

  /// Displays only movie releases.
  movies,

  /// Displays only series episodes.
  series;

  /// Returns the display label for this media filter.
  String get label {
    switch (this) {
      case CalendarMediaType.all:
        return 'All media';
      case CalendarMediaType.movies:
        return 'Movies';
      case CalendarMediaType.series:
        return 'Series';
    }
  }
}

/// Represents a unified calendar item.
class CalendarEvent extends Equatable {
  /// Identifier of the server that owns this event.
  final String? instanceId;

  /// Service type of the server that owns this event.
  final InstanceType? instanceType;

  /// The date and time of the release or airing.
  final DateTime releaseDate;

  /// The type of release or airing.
  final CalendarEventType type;

  /// The movie associated with this event.
  final Movie? movie;

  /// The episode associated with this event.
  final Episode? episode;

  /// The series associated with this event.
  final Series? series;

  const CalendarEvent({
    this.instanceId,
    this.instanceType,
    required this.releaseDate,
    required this.type,
    this.movie,
    this.episode,
    this.series,
  });

  /// Returns whether this event belongs to a movie.
  bool get isMovie => type != CalendarEventType.episode;

  /// Returns whether this event belongs to an episode.
  bool get isEpisode => type == CalendarEventType.episode;

  /// Returns whether the media and episode are monitored.
  bool get isMonitored {
    if (isMovie) {
      return movie?.monitored ?? false;
    }
    return (episode?.monitored ?? false) && (series?.monitored ?? true);
  }

  /// Returns whether this event is a series or season premiere.
  bool get isPremiere =>
      isEpisode &&
      (episode?.seasonNumber ?? 0) > 0 &&
      episode?.episodeNumber == 1;

  /// Returns whether this event is a special episode.
  bool get isSpecial =>
      isEpisode && (episode?.seasonNumber == 0 || episode?.episodeNumber == 0);

  /// Returns the title of the event.
  String get title => isMovie
      ? movie?.title ?? 'Unknown Movie'
      : series?.title ?? 'Unknown Series';

  /// Returns the event subtitle.
  String get subtitle {
    if (isEpisode) {
      final seasonNumber = episode?.seasonNumber ?? 0;
      final episodeNumber = episode?.episodeNumber ?? 0;
      final episodeTitle = episode?.title ?? 'TBA';
      return '${seasonNumber}x${episodeNumber.toString().padLeft(2, '0')} - $episodeTitle';
    }

    final year = movie?.year ?? 0;
    return year > 0 ? '$year · ${type.label}' : type.label;
  }

  @override
  List<Object?> get props => [
    instanceId,
    instanceType,
    releaseDate,
    type,
    movie,
    episode,
    series,
  ];
}

/// Stores the active calendar filters.
class CalendarFilters extends Equatable {
  /// Identifier of the selected instance, or null for every instance.
  final String? instanceId;

  /// Selected media type.
  final CalendarMediaType mediaType;

  /// Whether only monitored media should be displayed.
  final bool onlyMonitored;

  /// Whether only series and season premieres should be displayed.
  final bool onlyPremieres;

  /// Whether special episodes should be hidden.
  final bool hideSpecials;

  const CalendarFilters({
    this.instanceId,
    this.mediaType = CalendarMediaType.all,
    this.onlyMonitored = false,
    this.onlyPremieres = false,
    this.hideSpecials = false,
  });

  /// Returns whether any non-default filter is active.
  bool get isActive =>
      instanceId != null ||
      mediaType != CalendarMediaType.all ||
      onlyMonitored ||
      onlyPremieres ||
      hideSpecials;

  /// Applies these filters to calendar [events].
  List<CalendarEvent> apply(Iterable<CalendarEvent> events) {
    return events.where(_includes).toList();
  }

  bool _includes(CalendarEvent event) {
    if (instanceId != null && event.instanceId != instanceId) {
      return false;
    }
    if (mediaType == CalendarMediaType.movies && !event.isMovie) {
      return false;
    }
    if (mediaType == CalendarMediaType.series && !event.isEpisode) {
      return false;
    }
    if (onlyMonitored && !event.isMonitored) {
      return false;
    }
    if (onlyPremieres && event.isEpisode && !event.isPremiere) {
      return false;
    }
    if (hideSpecials && event.isSpecial) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
    instanceId,
    mediaType,
    onlyMonitored,
    onlyPremieres,
    hideSpecials,
  ];
}

/// Describes a calendar request failure for one configured instance.
class CalendarInstanceFailure extends Equatable {
  /// Identifier of the failed instance.
  final String instanceId;

  /// Type of the failed instance.
  final InstanceType instanceType;

  /// User-facing instance label.
  final String instanceLabel;

  /// Safe user-facing failure description.
  final String message;

  const CalendarInstanceFailure({
    required this.instanceId,
    required this.instanceType,
    required this.instanceLabel,
    required this.message,
  });

  @override
  List<Object?> get props => [instanceId, instanceType, instanceLabel, message];
}

/// Tracks calendar range loading and per-instance failures.
class CalendarLoadStatus extends Equatable {
  /// Failures encountered while loading the current range.
  final List<CalendarInstanceFailure> failures;

  /// Whether an additional future range is being loaded.
  final bool isLoadingMore;

  /// Earliest requested date.
  final DateTime? loadedStart;

  /// Latest requested date.
  final DateTime? loadedEnd;

  const CalendarLoadStatus({
    this.failures = const [],
    this.isLoadingMore = false,
    this.loadedStart,
    this.loadedEnd,
  });

  /// Returns whether any instance failed.
  bool get hasFailures => failures.isNotEmpty;

  @override
  List<Object?> get props => [failures, isLoadingMore, loadedStart, loadedEnd];
}

/// Provides the current time used to create the initial calendar range.
final calendarNowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Stores the active calendar filters.
final calendarFiltersProvider =
    NotifierProvider.autoDispose<CalendarFiltersNotifier, CalendarFilters>(
      CalendarFiltersNotifier.new,
    );

/// Fetches calendar events from every configured Radarr and Sonarr instance.
final calendarProvider =
    AsyncNotifierProvider.autoDispose<CalendarNotifier, List<CalendarEvent>>(
      CalendarNotifier.new,
    );

/// Exposes loading metadata and per-instance failures.
final calendarLoadStatusProvider = Provider.autoDispose<CalendarLoadStatus>((
  ref,
) {
  ref.watch(calendarProvider);
  return ref.watch(calendarProvider.notifier).loadStatus;
});

/// Exposes calendar events after applying the active filters.
final filteredCalendarProvider =
    Provider.autoDispose<AsyncValue<List<CalendarEvent>>>((ref) {
      final filters = ref.watch(calendarFiltersProvider);
      return ref.watch(calendarProvider).whenData(filters.apply);
    });

/// Manages the active calendar filters.
class CalendarFiltersNotifier extends AutoDisposeNotifier<CalendarFilters> {
  @override
  CalendarFilters build() => const CalendarFilters();

  /// Selects an instance, or every instance when [instanceId] is null.
  void selectInstance(String? instanceId) {
    state = CalendarFilters(
      instanceId: instanceId,
      mediaType: state.mediaType,
      onlyMonitored: state.onlyMonitored,
      onlyPremieres: state.onlyPremieres,
      hideSpecials: state.hideSpecials,
    );
  }

  /// Selects which media type is displayed.
  void selectMediaType(CalendarMediaType mediaType) {
    state = CalendarFilters(
      instanceId: state.instanceId,
      mediaType: mediaType,
      onlyMonitored: state.onlyMonitored,
      onlyPremieres: state.onlyPremieres,
      hideSpecials: state.hideSpecials,
    );
  }

  /// Enables or disables the monitored-only filter.
  void setOnlyMonitored(bool value) {
    state = CalendarFilters(
      instanceId: state.instanceId,
      mediaType: state.mediaType,
      onlyMonitored: value,
      onlyPremieres: state.onlyPremieres,
      hideSpecials: state.hideSpecials,
    );
  }

  /// Enables or disables the premiere-only filter.
  void setOnlyPremieres(bool value) {
    state = CalendarFilters(
      instanceId: state.instanceId,
      mediaType: state.mediaType,
      onlyMonitored: state.onlyMonitored,
      onlyPremieres: value,
      hideSpecials: state.hideSpecials,
    );
  }

  /// Enables or disables hiding special episodes.
  void setHideSpecials(bool value) {
    state = CalendarFilters(
      instanceId: state.instanceId,
      mediaType: state.mediaType,
      onlyMonitored: state.onlyMonitored,
      onlyPremieres: state.onlyPremieres,
      hideSpecials: value,
    );
  }

  /// Restores every calendar filter to its default value.
  void reset() {
    state = const CalendarFilters();
  }
}

/// Manages fetching, refreshing, and extending calendar events.
class CalendarNotifier extends AutoDisposeAsyncNotifier<List<CalendarEvent>> {
  static const _initialPastDays = 7;
  static const _rangeDays = 45;
  List<CalendarInstanceFailure> _failures = const [];
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  DateTime? _loadedStart;
  DateTime? _loadedEnd;

  /// Monotonic generation token incremented whenever [build] or [refresh]
  /// starts, so late completions from an abandoned fetch cannot overwrite a
  /// newer state, its failures, or its loaded range boundaries.
  int _generation = 0;

  /// Returns the current range loading metadata.
  CalendarLoadStatus get loadStatus => CalendarLoadStatus(
    failures: _failures,
    isLoadingMore: _isLoadingMore,
    loadedStart: _loadedStart,
    loadedEnd: _loadedEnd,
  );

  @override
  Future<List<CalendarEvent>> build() async {
    final radarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    );
    final sonarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    );
    final now = ref.watch(calendarNowProvider);
    final start = now.subtract(const Duration(days: _initialPastDays));
    final end = now.add(const Duration(days: _rangeDays));
    _failures = const [];
    _isLoadingMore = false;
    _isRefreshing = false;
    _loadedStart = start;
    _loadedEnd = end;
    final generation = ++_generation;

    final result = await _fetchRange(start, end, [
      ...radarrInstances,
      ...sonarrInstances,
    ]);
    if (generation != _generation) return state.valueOrNull ?? const [];
    _failures = result.failures;
    return _sortAndDeduplicate(result.events);
  }

  /// Loads the next future date range without replacing current events.
  Future<void> loadMore() async {
    final currentEvents = state.valueOrNull;
    final start = _loadedEnd;
    if (currentEvents == null ||
        start == null ||
        _isLoadingMore ||
        _isRefreshing ||
        state.isLoading) {
      return;
    }

    final end = start.add(const Duration(days: _rangeDays));
    final generation = _generation;
    _isLoadingMore = true;
    state = const AsyncLoading<List<CalendarEvent>>().copyWithPrevious(state);
    try {
      final result = await _fetchRange(start, end, _configuredInstances());
      if (generation != _generation) return;
      _failures = _mergeFailures(_failures, result.failures);
      _loadedEnd = end;
      _isLoadingMore = false;
      state = AsyncData(
        _sortAndDeduplicate([...currentEvents, ...result.events]),
      );
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      _isLoadingMore = false;
      state = AsyncError(error, stackTrace);
      logger.error('[CalendarProvider] Loading more failed', error, stackTrace);
    } finally {
      if (generation == _generation) {
        _isLoadingMore = false;
      }
    }
  }

  /// Reloads the complete requested range while preserving failed origins.
  Future<void> refresh() async {
    if (_isRefreshing || _isLoadingMore) {
      return;
    }
    final currentEvents = state.valueOrNull ?? const <CalendarEvent>[];
    if (state.isLoading && currentEvents.isEmpty) {
      return;
    }
    final now = ref.read(calendarNowProvider);
    final start =
        _loadedStart ?? now.subtract(const Duration(days: _initialPastDays));
    final end = _loadedEnd ?? now.add(const Duration(days: _rangeDays));
    final generation = ++_generation;
    _isRefreshing = true;
    state = const AsyncLoading<List<CalendarEvent>>().copyWithPrevious(state);
    try {
      final result = await _fetchRange(start, end, _configuredInstances());
      if (generation != _generation) return;
      final successfulOrigins = result.successfulOriginKeys;
      final retainedEvents = currentEvents.where(
        (event) => !successfulOrigins.contains(_originKeyForEvent(event)),
      );
      _failures = result.failures;
      _loadedStart = start;
      _loadedEnd = end;
      state = AsyncData(
        _sortAndDeduplicate([...retainedEvents, ...result.events]),
      );
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      state = AsyncError(error, stackTrace);
      logger.error('[CalendarProvider] Refresh failed', error, stackTrace);
    } finally {
      if (generation == _generation) {
        _isRefreshing = false;
      }
    }
  }

  List<Instance> _configuredInstances() {
    return [
      ...ref.read(instancesByTypeProvider(InstanceType.radarr)),
      ...ref.read(instancesByTypeProvider(InstanceType.sonarr)),
    ];
  }

  Future<_CalendarRangeResult> _fetchRange(
    DateTime start,
    DateTime end,
    List<Instance> instances,
  ) async {
    final requests = instances.map((instance) {
      if (instance.type == InstanceType.radarr) {
        return _fetchMovieEvents(instance, start: start, end: end);
      }
      return _fetchEpisodeEvents(instance, start: start, end: end);
    });
    final origins = await Future.wait(requests);
    return _CalendarRangeResult(origins);
  }

  Future<_CalendarOriginResult> _fetchMovieEvents(
    Instance instance, {
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final repository = ref.read(movieRepositoryForInstanceProvider(instance));
      final movies = await repository.getCalendar(start: start, end: end);
      final events = <CalendarEvent>[];

      for (final movie in movies) {
        final dates = <(DateTime?, CalendarEventType)>[
          (movie.inCinemas, CalendarEventType.cinema),
          (movie.digitalRelease, CalendarEventType.digital),
          (movie.physicalRelease, CalendarEventType.physical),
        ];
        for (final (date, type) in dates) {
          if (date != null && _isWithinRange(date, start, end)) {
            events.add(
              CalendarEvent(
                instanceId: instance.id,
                instanceType: instance.type,
                releaseDate: date,
                type: type,
                movie: movie,
              ),
            );
          }
        }
      }

      return _CalendarOriginResult.success(instance, events);
    } catch (error, stackTrace) {
      logger.error(
        '[CalendarProvider] Movies fetch failed for instance ${instance.id}',
        error,
        stackTrace,
      );
      return _CalendarOriginResult.failure(instance);
    }
  }

  Future<_CalendarOriginResult> _fetchEpisodeEvents(
    Instance instance, {
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final repository = ref.read(
        seriesRepositoryForInstanceProvider(instance),
      );
      final episodes = await repository.getCalendar(start: start, end: end);
      final events = episodes
          .where(
            (episode) =>
                episode.airDateUtc != null &&
                _isWithinRange(episode.airDateUtc!, start, end),
          )
          .map(
            (episode) => CalendarEvent(
              instanceId: instance.id,
              instanceType: instance.type,
              releaseDate: episode.airDateUtc!,
              type: CalendarEventType.episode,
              episode: episode,
              series: episode.series,
            ),
          )
          .toList();
      return _CalendarOriginResult.success(instance, events);
    } catch (error, stackTrace) {
      logger.error(
        '[CalendarProvider] Series fetch failed for instance ${instance.id}',
        error,
        stackTrace,
      );
      return _CalendarOriginResult.failure(instance);
    }
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  List<CalendarInstanceFailure> _mergeFailures(
    List<CalendarInstanceFailure> existing,
    List<CalendarInstanceFailure> added,
  ) {
    final failures = {
      for (final failure in existing) _originKeyForFailure(failure): failure,
      for (final failure in added) _originKeyForFailure(failure): failure,
    };
    return failures.values.toList();
  }

  List<CalendarEvent> _sortAndDeduplicate(Iterable<CalendarEvent> events) {
    final uniqueEvents = <String, CalendarEvent>{};
    for (final event in events) {
      uniqueEvents[_eventKey(event)] = event;
    }
    final sortedEvents = uniqueEvents.values.toList();
    sortedEvents.sort((first, second) {
      final dateComparison = first.releaseDate.compareTo(second.releaseDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      final typeComparison = first.type.sortPriority.compareTo(
        second.type.sortPriority,
      );
      if (typeComparison != 0) {
        return typeComparison;
      }
      return first.title.compareTo(second.title);
    });
    return sortedEvents;
  }

  String _eventKey(CalendarEvent event) {
    final mediaKey = event.isMovie
        ? 'movie:${event.movie?.id}:${event.type.name}'
        : 'episode:${event.episode?.id}';
    return '${_originKeyForEvent(event)}:$mediaKey';
  }

  String _originKeyForEvent(CalendarEvent event) {
    return '${event.instanceType?.name}:${event.instanceId}';
  }

  String _originKeyForFailure(CalendarInstanceFailure failure) {
    return '${failure.instanceType.name}:${failure.instanceId}';
  }
}

class _CalendarOriginResult {
  final Instance instance;
  final List<CalendarEvent> events;
  final CalendarInstanceFailure? failure;

  const _CalendarOriginResult._({
    required this.instance,
    required this.events,
    this.failure,
  });

  factory _CalendarOriginResult.success(
    Instance instance,
    List<CalendarEvent> events,
  ) {
    return _CalendarOriginResult._(instance: instance, events: events);
  }

  factory _CalendarOriginResult.failure(Instance instance) {
    return _CalendarOriginResult._(
      instance: instance,
      events: const [],
      failure: CalendarInstanceFailure(
        instanceId: instance.id,
        instanceType: instance.type,
        instanceLabel: instance.label,
        message: 'Calendar data could not be loaded.',
      ),
    );
  }

  String get originKey => '${instance.type.name}:${instance.id}';
}

class _CalendarRangeResult {
  final List<_CalendarOriginResult> origins;

  const _CalendarRangeResult(this.origins);

  List<CalendarEvent> get events =>
      origins.expand((origin) => origin.events).toList();

  List<CalendarInstanceFailure> get failures => origins
      .map((origin) => origin.failure)
      .whereType<CalendarInstanceFailure>()
      .toList();

  Set<String> get successfulOriginKeys => origins
      .where((origin) => origin.failure == null)
      .map((origin) => origin.originKey)
      .toSet();
}
