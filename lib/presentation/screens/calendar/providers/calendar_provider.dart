import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';

/// Represents a unified calendar item (either a movie release or an episode).
class CalendarEvent extends Equatable {
  /// The date and time of the release/airing.
  final DateTime releaseDate;

  /// The movie associated with this event (if any).
  final Movie? movie;

  /// The episode associated with this event (if any).
  final Episode? episode;

  /// The series associated with this event (if any, for episodes).
  final Series? series;

  const CalendarEvent({
    required this.releaseDate,
    this.movie,
    this.episode,
    this.series,
  });

  /// Returns true if this event is for a movie.
  bool get isMovie => movie != null;

  /// Returns true if this event is for an episode.
  bool get isEpisode => episode != null;

  /// Returns the title of the event (Movie title or Series title).
  String get title =>
      isMovie ? movie!.title : series?.title ?? 'Unknown Series';

  /// Returns the subtitle (Year for movies, SxxExx - Title for episodes).
  String get subtitle => isMovie
      ? (movie!.year > 0 ? '${movie!.year}' : '')
      : '${episode!.seasonNumber}x${episode!.episodeNumber.toString().padLeft(2, '0')} - ${episode!.title}';

  @override
  List<Object?> get props => [releaseDate, movie, episode, series];
}

/// Provider for fetching calendar events from both Radarr and Sonarr.
final calendarProvider =
    AsyncNotifierProvider.autoDispose<CalendarNotifier, List<CalendarEvent>>(
      CalendarNotifier.new,
    );

/// Manages fetching and grouping of calendar events.
class CalendarNotifier extends AutoDisposeAsyncNotifier<List<CalendarEvent>> {
  @override
  Future<List<CalendarEvent>> build() async {
    return _fetchCalendar();
  }

  Future<List<CalendarEvent>> _fetchCalendar() async {
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final end = now.add(const Duration(days: 45));

    final events = <CalendarEvent>[];

    if (movieRepo != null) {
      try {
        final movies = await movieRepo.getCalendar(start: start, end: end);
        events.addAll(
          movies.map((m) {
            final date =
                m.physicalRelease ?? m.digitalRelease ?? m.inCinemas ?? m.added;
            return CalendarEvent(releaseDate: date, movie: m);
          }),
        );
      } catch (e, stack) {
        logger.error('calendar: movies fetch failed', e, stack);
      }
    }

    if (seriesRepo != null) {
      try {
        final episodes = await seriesRepo.getCalendar(start: start, end: end);
        events.addAll(
          episodes.map((e) {
            return CalendarEvent(
              releaseDate: e.airDateUtc ?? now,
              episode: e,
              series: e.series,
            );
          }),
        );
      } catch (e, stack) {
        logger.error('calendar: series fetch failed', e, stack);
      }
    }

    events.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));

    return events;
  }

  /// Refreshes the calendar data.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
