import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';

/// Defines the type of release or airing for a calendar event.
enum CalendarEventType {
  /// Movie theatrical release (in cinemas).
  cinema,

  /// Movie digital release (streaming/VOD).
  digital,

  /// Movie physical release (Blu-ray/DVD).
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
  /// Lower number = earlier in the list.
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

/// Represents a unified calendar item (either a movie release or an episode).
class CalendarEvent extends Equatable {
  /// The date and time of the release/airing.
  final DateTime releaseDate;

  /// The type of release or airing.
  final CalendarEventType type;

  /// The movie associated with this event (if any).
  final Movie? movie;

  /// The episode associated with this event (if any).
  final Episode? episode;

  /// The series associated with this event (if any, for episodes).
  final Series? series;

  const CalendarEvent({
    required this.releaseDate,
    required this.type,
    this.movie,
    this.episode,
    this.series,
  });

  /// Returns true if this event is for a movie.
  bool get isMovie => type != CalendarEventType.episode;

  /// Returns true if this event is for an episode.
  bool get isEpisode => type == CalendarEventType.episode;

  /// Returns the title of the event (Movie title or Series title).
  String get title =>
      isMovie ? movie!.title : series?.title ?? 'Unknown Series';

  /// Returns the subtitle (Year for movies, SxxExx - Title for episodes).
  String get subtitle {
    if (isEpisode) {
      return '${episode!.seasonNumber}x${episode!.episodeNumber.toString().padLeft(2, '0')} - ${episode!.title}';
    }

    final yearLabel = (movie!.year > 0 ? '${movie!.year}' : '');
    return yearLabel.isNotEmpty ? '$yearLabel · ${type.label}' : type.label;
  }

  @override
  List<Object?> get props => [releaseDate, type, movie, episode, series];
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

        for (final m in movies) {
          // Generate cinema event
          if (m.inCinemas != null &&
              m.inCinemas!.isAfter(start) &&
              m.inCinemas!.isBefore(end)) {
            events.add(
              CalendarEvent(
                releaseDate: m.inCinemas!,
                type: CalendarEventType.cinema,
                movie: m,
              ),
            );
          }

          // Generate digital release event
          if (m.digitalRelease != null &&
              m.digitalRelease!.isAfter(start) &&
              m.digitalRelease!.isBefore(end)) {
            events.add(
              CalendarEvent(
                releaseDate: m.digitalRelease!,
                type: CalendarEventType.digital,
                movie: m,
              ),
            );
          }

          // Generate physical release event
          if (m.physicalRelease != null &&
              m.physicalRelease!.isAfter(start) &&
              m.physicalRelease!.isBefore(end)) {
            events.add(
              CalendarEvent(
                releaseDate: m.physicalRelease!,
                type: CalendarEventType.physical,
                movie: m,
              ),
            );
          }

          // Fallback: If no specific release dates, use 'added' date as digital
          if (m.inCinemas == null &&
              m.digitalRelease == null &&
              m.physicalRelease == null) {
            events.add(
              CalendarEvent(
                releaseDate: m.added,
                type: CalendarEventType.digital,
                movie: m,
              ),
            );
          }
        }
      } catch (e, stack) {
        logger.error('[CalendarProvider] Movies fetch failed', e, stack);
      }
    }

    if (seriesRepo != null) {
      try {
        final episodes = await seriesRepo.getCalendar(start: start, end: end);
        events.addAll(
          episodes.map((e) {
            return CalendarEvent(
              releaseDate: e.airDateUtc ?? now,
              type: CalendarEventType.episode,
              episode: e,
              series: e.series,
            );
          }),
        );
      } catch (e, stack) {
        logger.error('[CalendarProvider] Series fetch failed', e, stack);
      }
    }

    // Sort by date first, then by event type priority
    events.sort((a, b) {
      final dateComparison = a.releaseDate.compareTo(b.releaseDate);
      if (dateComparison != 0) return dateComparison;
      return a.type.sortPriority.compareTo(b.type.sortPriority);
    });

    return events;
  }

  /// Refreshes the calendar data.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
