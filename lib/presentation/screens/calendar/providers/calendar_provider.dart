import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';

// Unified Calendar Event Model
class CalendarEvent extends Equatable {
  final DateTime releaseDate;
  final Movie? movie;
  final Episode? episode;
  final Series? series; // For episode context

  const CalendarEvent({
    required this.releaseDate,
    this.movie,
    this.episode,
    this.series,
  });

  bool get isMovie => movie != null;
  bool get isEpisode => episode != null;

  String get title =>
      isMovie ? movie!.title : series?.title ?? 'Unknown Series';
  String get subtitle => isMovie
      ? (movie!.year > 0 ? '${movie!.year}' : '')
      : '${episode!.seasonNumber}x${episode!.episodeNumber.toString().padLeft(2, '0')} - ${episode!.title}';

  @override
  List<Object?> get props => [releaseDate, movie, episode, series];
}

final calendarProvider =
    AsyncNotifierProvider.autoDispose<CalendarNotifier, List<CalendarEvent>>(
      CalendarNotifier.new,
    );

// Changed to AsyncNotifier, provider.autoDispose handles part of it,
// but technically for autoDispose provider we usually extend AutoDisposeAsyncNotifier.
// If that class is missing (older riverpod?), we might need to check.
// Using AsyncNotifier with autoDispose provider works if we don't need 'ref.keepAlive' specifically inside?
// Actually Dart requires specific class for type safety in provider.
// If 'AutoDisposeAsyncNotifier' is undefined, I will try just 'AsyncNotifier'.
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

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
