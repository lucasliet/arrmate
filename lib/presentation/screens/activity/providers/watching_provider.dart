import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/playback_launch_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import '../../../providers/jellyfin_session_state_provider.dart';

/// A movie paired with the Radarr [Instance] that owns it.
class LibraryMovieEntry {
  /// The Radarr instance that holds [movie].
  final Instance instance;

  /// The library movie.
  final Movie movie;

  /// Creates a [LibraryMovieEntry].
  const LibraryMovieEntry({required this.instance, required this.movie});
}

/// A series paired with the Sonarr [Instance] that owns it.
class LibrarySeriesEntry {
  /// The Sonarr instance that holds [series].
  final Instance instance;

  /// The library series.
  final Series series;

  /// Creates a [LibrarySeriesEntry].
  const LibrarySeriesEntry({required this.instance, required this.series});
}

/// An in-progress Jellyfin item matched to a Radarr [Movie] or Sonarr [Series]
/// in the app library.
class WatchingItem {
  /// The in-progress item reported by Jellyfin.
  final JellyfinItem jellyfinItem;

  /// The Radarr or Sonarr instance that owns the matched library entry.
  final Instance mediaInstance;

  /// The matched Radarr movie when [jellyfinItem] is a movie.
  final Movie? movie;

  /// The matched Sonarr series when [jellyfinItem] is an episode.
  final Series? series;

  /// Creates a [WatchingItem] backed by either a [movie] or a [series].
  const WatchingItem({
    required this.jellyfinItem,
    required this.mediaInstance,
    this.movie,
    this.series,
  }) : assert(
         (movie != null) ^ (series != null),
         'WatchingItem must be backed by either a movie or a series.',
       );

  /// Whether this item represents a movie.
  bool get isMovie => movie != null;

  /// Whether this item represents an episode of a series.
  bool get isEpisode => series != null;

  /// Primary title shown on the card (movie title or series title).
  String get displayTitle => isMovie ? movie!.title : series!.title;

  /// Secondary line shown below [displayTitle].
  ///
  /// For episodes, formats `SxxExx · Episode Name` when season/episode numbers
  /// are present; for movies, returns the release year when known.
  String? get subtitle {
    if (isMovie) {
      final year = movie!.year;
      return year > 0 ? '$year' : null;
    }
    final season = jellyfinItem.parentIndexNumber;
    final episode = jellyfinItem.indexNumber;
    final episodeName = jellyfinItem.name?.trim();
    if (season != null && episode != null) {
      final code = formatEpisodeNumber(season, episode, short: true);
      if (episodeName != null && episodeName.isNotEmpty) {
        return '$code · $episodeName';
      }
      return code;
    }
    if (episodeName != null && episodeName.isNotEmpty) {
      return episodeName;
    }
    return null;
  }

  /// Title passed to the in-app video player when resuming playback.
  String get playbackTitle {
    if (isMovie) return movie!.title;
    final episodeSub = subtitle;
    if (episodeSub != null && episodeSub.isNotEmpty) {
      return '${series!.title} · $episodeSub';
    }
    return series!.title;
  }

  /// Watched fraction between `0.0` and `1.0`.
  double get progress {
    final pos = jellyfinItem.playbackPositionTicks ?? 0;
    final total = jellyfinItem.runTimeTicks ?? 0;
    if (pos <= 0 || total <= 0) return 0;
    return (pos / total).clamp(0.0, 1.0);
  }

  /// Current resume position converted from Jellyfin's 100ns ticks.
  Duration get positionDuration =>
      Duration(microseconds: (jellyfinItem.playbackPositionTicks ?? 0) ~/ 10);

  /// Total runtime converted from Jellyfin's 100ns ticks, when known.
  Duration? get totalDuration {
    final total = jellyfinItem.runTimeTicks;
    if (total == null || total <= 0) return null;
    return Duration(microseconds: total ~/ 10);
  }

  /// Remaining playback duration, when [totalDuration] is available.
  Duration? get remainingDuration {
    final total = totalDuration;
    if (total == null) return null;
    final remaining = total - positionDuration;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Provider for Jellyfin "Continue Watching" items that have parity with the
/// configured Radarr/Sonarr libraries.
final watchingItemsProvider =
    AsyncNotifierProvider.autoDispose<WatchingNotifier, List<WatchingItem>>(
      WatchingNotifier.new,
    );

/// Notifier that loads Jellyfin resume items and filters them against the
/// configured Radarr and Sonarr libraries.
class WatchingNotifier extends AutoDisposeAsyncNotifier<List<WatchingItem>> {
  @override
  Future<List<WatchingItem>> build() async {
    final jellyfinInstance = ref.watch(currentJellyfinInstanceProvider);
    if (jellyfinInstance == null) return const [];

    final expiredIds = ref.watch(jellyfinSessionExpiredProvider);
    if (expiredIds.contains(jellyfinInstance.id)) return const [];

    final radarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    );
    final sonarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    );
    if (radarrInstances.isEmpty && sonarrInstances.isEmpty) {
      return const [];
    }

    final jellyfin = ref
        .watch(playbackLaunchServiceProvider)
        .serviceFor(jellyfinInstance);

    List<JellyfinItem> resumeItems;
    try {
      resumeItems = await jellyfin.getResumeItems();
    } on UnauthorizedError {
      logger.warning(
        '[WatchingNotifier] Jellyfin session expired for instance '
        '${jellyfinInstance.id}',
      );
      final sessionExpiredNotifier = ref.read(
        jellyfinSessionExpiredProvider.notifier,
      );
      Future.microtask(
        () => Future.microtask(
          () => sessionExpiredNotifier.markExpired(jellyfinInstance.id),
        ),
      );
      return const [];
    } catch (e, stackTrace) {
      logger.warning(
        '[WatchingNotifier] Failed to fetch Jellyfin resume items',
        e,
        stackTrace,
      );
      return const [];
    }

    if (resumeItems.isEmpty) return const [];

    final needsMovies = resumeItems.any(
      (item) => item.type?.toLowerCase() == 'movie',
    );
    final needsSeries = resumeItems.any(
      (item) => item.type?.toLowerCase() == 'episode',
    );

    final moviesFuture = needsMovies
        ? _loadMovies(radarrInstances)
        : Future.value(const <LibraryMovieEntry>[]);
    final seriesFuture = needsSeries
        ? _loadSeries(sonarrInstances)
        : Future.value(const <LibrarySeriesEntry>[]);

    final results = await Future.wait([moviesFuture, seriesFuture]);
    final movies = results[0] as List<LibraryMovieEntry>;
    final series = results[1] as List<LibrarySeriesEntry>;

    return matchResumeItemsToLibrary(
      resumeItems: resumeItems,
      movies: movies,
      series: series,
    );
  }

  /// Refreshes the Continue Watching list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<List<LibraryMovieEntry>> _loadMovies(List<Instance> instances) async {
    final lists = await Future.wait(
      instances.map((instance) async {
        try {
          final repo = ref.read(movieRepositoryForInstanceProvider(instance));
          final items = await repo.getMovies();
          return [
            for (final movie in items)
              LibraryMovieEntry(instance: instance, movie: movie),
          ];
        } catch (e, stackTrace) {
          logger.warning(
            '[WatchingNotifier] Failed to load movies from ${instance.label}',
            e,
            stackTrace,
          );
          return const <LibraryMovieEntry>[];
        }
      }),
    );
    return [for (final list in lists) ...list];
  }

  Future<List<LibrarySeriesEntry>> _loadSeries(List<Instance> instances) async {
    final lists = await Future.wait(
      instances.map((instance) async {
        try {
          final repo = ref.read(seriesRepositoryForInstanceProvider(instance));
          final items = await repo.getSeries();
          return [
            for (final show in items)
              LibrarySeriesEntry(instance: instance, series: show),
          ];
        } catch (e, stackTrace) {
          logger.warning(
            '[WatchingNotifier] Failed to load series from ${instance.label}',
            e,
            stackTrace,
          );
          return const <LibrarySeriesEntry>[];
        }
      }),
    );
    return [for (final list in lists) ...list];
  }
}

/// Filters and pairs Jellyfin [resumeItems] with [movies] and [series] from
/// the user's Radarr/Sonarr libraries, preserving Jellyfin's resume order.
List<WatchingItem> matchResumeItemsToLibrary({
  required List<JellyfinItem> resumeItems,
  required List<LibraryMovieEntry> movies,
  required List<LibrarySeriesEntry> series,
}) {
  final matched = <WatchingItem>[];
  for (final item in resumeItems) {
    final type = item.type?.toLowerCase();
    if (type == 'movie') {
      final entry = _matchMovie(item, movies);
      if (entry != null) {
        matched.add(
          WatchingItem(
            jellyfinItem: item,
            mediaInstance: entry.instance,
            movie: entry.movie,
          ),
        );
      }
    } else if (type == 'episode') {
      final entry = _matchSeries(item, series);
      if (entry != null) {
        matched.add(
          WatchingItem(
            jellyfinItem: item,
            mediaInstance: entry.instance,
            series: entry.series,
          ),
        );
      }
    }
  }
  return matched;
}

LibraryMovieEntry? _matchMovie(
  JellyfinItem item,
  List<LibraryMovieEntry> movies,
) {
  if (movies.isEmpty) return null;

  final tmdbId = int.tryParse(_providerId(item, 'tmdb') ?? '');
  if (tmdbId != null && tmdbId > 0) {
    for (final entry in movies) {
      if (entry.movie.tmdbId == tmdbId) return entry;
    }
  }

  final imdbId = _providerId(item, 'imdb')?.trim().toLowerCase();
  if (imdbId != null && imdbId.isNotEmpty) {
    for (final entry in movies) {
      if (entry.movie.imdbId?.trim().toLowerCase() == imdbId) return entry;
    }
  }

  final candidatePaths = _itemPaths(item);
  if (candidatePaths.isNotEmpty) {
    for (final entry in movies) {
      final movieFilePath = _normalizePath(entry.movie.movieFile?.path);
      final movieFolderPath = _normalizePath(entry.movie.path);
      for (final itemPath in candidatePaths) {
        if (movieFilePath != null &&
            (itemPath == movieFilePath ||
                _basename(itemPath) == _basename(movieFilePath))) {
          return entry;
        }
        if (movieFolderPath != null &&
            (itemPath == movieFolderPath ||
                itemPath.startsWith('$movieFolderPath/'))) {
          return entry;
        }
      }
    }
  }

  final rawName = item.name?.trim();
  if (rawName != null && rawName.isNotEmpty) {
    final normalizedName = _normalizeTitle(rawName);
    if (normalizedName.isNotEmpty) {
      final itemYear = item.productionYear;
      for (final entry in movies) {
        if (_normalizeTitle(entry.movie.title) != normalizedName) continue;
        if (itemYear != null &&
            entry.movie.year > 0 &&
            entry.movie.year != itemYear) {
          continue;
        }
        return entry;
      }
    }
  }

  return null;
}

LibrarySeriesEntry? _matchSeries(
  JellyfinItem item,
  List<LibrarySeriesEntry> seriesList,
) {
  if (seriesList.isEmpty) return null;

  final candidatePaths = _itemPaths(item);
  if (candidatePaths.isNotEmpty) {
    for (final entry in seriesList) {
      final seriesFolder = _normalizePath(entry.series.path);
      if (seriesFolder == null) continue;
      for (final itemPath in candidatePaths) {
        if (itemPath == seriesFolder || itemPath.startsWith('$seriesFolder/')) {
          return entry;
        }
      }
    }
  }

  final rawSeriesName = item.seriesName?.trim();
  if (rawSeriesName != null && rawSeriesName.isNotEmpty) {
    final normalizedTarget = _normalizeSeriesTitle(rawSeriesName);
    if (normalizedTarget.isNotEmpty) {
      for (final entry in seriesList) {
        if (_normalizeSeriesTitle(entry.series.title) == normalizedTarget) {
          return entry;
        }
        final alternates = entry.series.alternateTitles ?? const [];
        for (final alt in alternates) {
          if (_normalizeSeriesTitle(alt.title) == normalizedTarget) {
            return entry;
          }
        }
      }
    }
  }

  return null;
}

String? _providerId(JellyfinItem item, String key) {
  final direct = item.providerIds[key];
  if (direct != null) return direct;
  final target = key.toLowerCase();
  for (final entry in item.providerIds.entries) {
    if (entry.key.toLowerCase() == target) return entry.value;
  }
  return null;
}

List<String> _itemPaths(JellyfinItem item) {
  return [
    _normalizePath(item.path),
    for (final source in item.mediaSources) _normalizePath(source.path),
  ].nonNulls.toList();
}

String? _normalizePath(String? path) {
  if (path == null) return null;
  var normalized = path.trim().replaceAll('\\', '/').toLowerCase();
  while (normalized.endsWith('/') && normalized.length > 1) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized.isEmpty ? null : normalized;
}

String _basename(String normalizedPath) {
  final slash = normalizedPath.lastIndexOf('/');
  return slash == -1 ? normalizedPath : normalizedPath.substring(slash + 1);
}

final RegExp _trailingYearPattern = RegExp(r'\s*\(\d{4}\)\s*$');
final RegExp _nonAlphanumericPattern = RegExp(r'[^a-z0-9]+');

String _normalizeSeriesTitle(String value) {
  final withoutYear = value.trim().replaceFirst(_trailingYearPattern, '');
  return _normalizeTitle(withoutYear);
}

String _normalizeTitle(String value) {
  return value.toLowerCase().replaceAll(_nonAlphanumericPattern, ' ').trim();
}
