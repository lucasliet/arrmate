import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarFilters', () {
    test('should filter by instance and media type', () {
      // Given
      final events = [
        _movieEvent(instanceId: 'home', monitored: true),
        _movieEvent(instanceId: 'remote', monitored: false, movieId: 2),
        _episodeEvent(instanceId: 'remote', episodeId: 3),
      ];
      const filters = CalendarFilters(
        instanceId: 'remote',
        mediaType: CalendarMediaType.movies,
      );

      // When
      final result = filters.apply(events);

      // Then
      expect(result, hasLength(1));
      expect(result.single.movie?.tmdbId, 2);
    });

    test('should require both episode and series to be monitored', () {
      // Given
      final events = [
        _episodeEvent(instanceId: 'home', episodeId: 1),
        _episodeEvent(instanceId: 'home', episodeId: 2, seriesMonitored: false),
        _movieEvent(instanceId: 'home', monitored: false),
      ];
      const filters = CalendarFilters(onlyMonitored: true);

      // When
      final result = filters.apply(events);

      // Then
      expect(result.map((event) => event.episode?.id), [1]);
    });

    test('should keep movies and only premiere episodes', () {
      // Given
      final events = [
        _movieEvent(instanceId: 'home', monitored: true),
        _episodeEvent(instanceId: 'home', episodeId: 1, episodeNumber: 1),
        _episodeEvent(instanceId: 'home', episodeId: 2, episodeNumber: 2),
      ];
      const filters = CalendarFilters(onlyPremieres: true);

      // When
      final result = filters.apply(events);

      // Then
      expect(result, hasLength(2));
      expect(result.any((event) => event.isMovie), isTrue);
      expect(
        result.where((event) => event.isEpisode).single.isPremiere,
        isTrue,
      );
    });

    test('should hide episodes from the specials season', () {
      // Given
      final events = [
        _episodeEvent(instanceId: 'home', episodeId: 1, seasonNumber: 0),
        _episodeEvent(instanceId: 'home', episodeId: 2),
      ];
      const filters = CalendarFilters(hideSpecials: true);

      // When
      final result = filters.apply(events);

      // Then
      expect(result.map((event) => event.episode?.id), [2]);
    });
  });
}

CalendarEvent _movieEvent({
  required String instanceId,
  required bool monitored,
  int movieId = 1,
}) {
  return CalendarEvent(
    instanceId: instanceId,
    instanceType: InstanceType.radarr,
    releaseDate: DateTime.utc(2026, 7, 30),
    type: CalendarEventType.digital,
    movie: Movie(
      guid: movieId,
      tmdbId: movieId,
      title: 'Movie $movieId',
      sortTitle: 'movie $movieId',
      year: 2026,
      runtime: 120,
      status: MovieStatus.released,
      isAvailable: true,
      minimumAvailability: MovieStatus.released,
      monitored: monitored,
      qualityProfileId: 1,
      added: DateTime.utc(2026),
    ),
  );
}

CalendarEvent _episodeEvent({
  required String instanceId,
  required int episodeId,
  int seasonNumber = 1,
  int episodeNumber = 2,
  bool seriesMonitored = true,
}) {
  final series = Series(
    guid: 10,
    tvdbId: 10,
    title: 'Series',
    sortTitle: 'series',
    monitored: seriesMonitored,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2026,
    added: DateTime.utc(2026),
  );
  return CalendarEvent(
    instanceId: instanceId,
    instanceType: InstanceType.sonarr,
    releaseDate: DateTime.utc(2026, 7, 30),
    type: CalendarEventType.episode,
    episode: Episode(
      id: episodeId,
      seriesId: 10,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      monitored: true,
      series: series,
    ),
    series: series,
  );
}
