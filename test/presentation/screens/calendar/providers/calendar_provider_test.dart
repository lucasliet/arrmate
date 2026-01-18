import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/calendar/providers/calendar_provider.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  late MockMovieRepository mockMovieRepository;
  late MockSeriesRepository mockSeriesRepository;

  setUp(() {
    mockMovieRepository = MockMovieRepository();
    mockSeriesRepository = MockSeriesRepository();
  });

  group('CalendarEventType', () {
    test('should have correct labels', () {
      expect(CalendarEventType.cinema.label, 'In Cinemas');
      expect(CalendarEventType.digital.label, 'Digital Release');
      expect(CalendarEventType.physical.label, 'Physical Release');
      expect(CalendarEventType.episode.label, 'Episode');
    });

    test('should have correct icons', () {
      expect(CalendarEventType.cinema.icon, Icons.theaters);
      expect(CalendarEventType.digital.icon, Icons.play_circle_outline);
      expect(CalendarEventType.physical.icon, Icons.album);
      expect(CalendarEventType.episode.icon, Icons.tv);
    });

    test('should have correct sort priority', () {
      expect(CalendarEventType.cinema.sortPriority, 0);
      expect(CalendarEventType.digital.sortPriority, 1);
      expect(CalendarEventType.physical.sortPriority, 2);
      expect(CalendarEventType.episode.sortPriority, 3);
    });
  });

  group('CalendarEvent', () {
    test('should identify movie events correctly', () {
      final movie = Movie(
        tmdbId: 1,
        title: 'Test Movie',
        sortTitle: 'test movie',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: DateTime.now(),
        qualityProfileId: 1,
        images: [],
      );

      final event = CalendarEvent(
        releaseDate: DateTime.now(),
        type: CalendarEventType.cinema,
        movie: movie,
      );

      expect(event.isMovie, true);
      expect(event.isEpisode, false);
      expect(event.title, 'Test Movie');
    });

    test('should identify episode events correctly', () {
      final series = Series(
        guid: 1,
        tvdbId: 123,
        title: 'Test Series',
        sortTitle: 'test series',
        monitored: true,
        status: SeriesStatus.continuing,
        seriesType: SeriesType.standard,
        added: DateTime.now(),
        images: [],
        seasons: [],
        tags: [],
        genres: [],
        year: 2023,
        runtime: 45,
      );

      final episode = Episode(
        id: 1,
        episodeNumber: 1,
        seasonNumber: 1,
        title: 'Test Episode',
        seriesId: 1,
        hasFile: false,
        monitored: true,
        airDateUtc: DateTime.now(),
        series: series,
      );

      final event = CalendarEvent(
        releaseDate: DateTime.now(),
        type: CalendarEventType.episode,
        episode: episode,
        series: series,
      );

      expect(event.isMovie, false);
      expect(event.isEpisode, true);
      expect(event.title, 'Test Series');
    });

    test('should include event type in movie subtitle', () {
      final movie = Movie(
        tmdbId: 1,
        title: 'Test Movie',
        sortTitle: 'test movie',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: DateTime.now(),
        qualityProfileId: 1,
        images: [],
      );

      final event = CalendarEvent(
        releaseDate: DateTime.now(),
        type: CalendarEventType.cinema,
        movie: movie,
      );

      expect(event.subtitle, '2023 · In Cinemas');
    });
  });

  group('CalendarNotifier', () {
    test('should generate multiple events for movie with multiple dates',
        () async {
      final now = DateTime.now();
      final inCinemas = now.add(const Duration(days: 1));
      final digitalRelease = now.add(const Duration(days: 20));
      final physicalRelease = now.add(const Duration(days: 40));

      final movie = Movie(
        tmdbId: 1,
        title: 'Test Movie',
        sortTitle: 'test movie',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: now,
        qualityProfileId: 1,
        images: [],
        inCinemas: inCinemas,
        digitalRelease: digitalRelease,
        physicalRelease: physicalRelease,
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockMovieRepository),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepository),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockMovieRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [movie]);

      when(() => mockSeriesRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      await container.read(calendarProvider.future);

      final events = container.read(calendarProvider).value!;

      // Should generate 3 events: cinema, digital, physical
      expect(events.length, 3);
      expect(
        events.where((e) => e.type == CalendarEventType.cinema).length,
        1,
      );
      expect(
        events.where((e) => e.type == CalendarEventType.digital).length,
        1,
      );
      expect(
        events.where((e) => e.type == CalendarEventType.physical).length,
        1,
      );
    });

    test('should generate single event for movie with only one date', () async {
      final now = DateTime.now();
      final inCinemas = now.add(const Duration(days: 1));

      final movie = Movie(
        tmdbId: 1,
        title: 'Test Movie',
        sortTitle: 'test movie',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: now,
        qualityProfileId: 1,
        images: [],
        inCinemas: inCinemas,
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockMovieRepository),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepository),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockMovieRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [movie]);

      when(() => mockSeriesRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      await container.read(calendarProvider.future);

      final events = container.read(calendarProvider).value!;

      // Should generate 1 event: cinema only
      expect(events.length, 1);
      expect(events.first.type, CalendarEventType.cinema);
    });

    test('should use fallback digital event for movie without specific dates',
        () async {
      final now = DateTime.now();

      final movie = Movie(
        tmdbId: 1,
        title: 'Test Movie',
        sortTitle: 'test movie',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: now,
        qualityProfileId: 1,
        images: [],
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockMovieRepository),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepository),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockMovieRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [movie]);

      when(() => mockSeriesRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      await container.read(calendarProvider.future);

      final events = container.read(calendarProvider).value!;

      // Should generate 1 event: digital fallback using 'added' date
      expect(events.length, 1);
      expect(events.first.type, CalendarEventType.digital);
      expect(events.first.releaseDate, movie.added);
    });

    test('should sort events by date and then by type priority', () async {
      final now = DateTime.now();
      final sameDate = now.add(const Duration(days: 10));

      final movie1 = Movie(
        tmdbId: 1,
        title: 'Movie 1',
        sortTitle: 'movie 1',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: now,
        qualityProfileId: 1,
        images: [],
        digitalRelease: sameDate,
      );

      final movie2 = Movie(
        tmdbId: 2,
        title: 'Movie 2',
        sortTitle: 'movie 2',
        runtime: 120,
        year: 2023,
        monitored: true,
        hasFile: false,
        isAvailable: true,
        minimumAvailability: MovieStatus.released,
        status: MovieStatus.released,
        added: now,
        qualityProfileId: 1,
        images: [],
        inCinemas: sameDate,
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockMovieRepository),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepository),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockMovieRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [movie1, movie2]);

      when(() => mockSeriesRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      await container.read(calendarProvider.future);

      final events = container.read(calendarProvider).value!;

      expect(events.length, 2);
      // Cinema should come before digital (same date, lower priority number)
      expect(events[0].type, CalendarEventType.cinema);
      expect(events[1].type, CalendarEventType.digital);
    });

    test('should handle episodes correctly', () async {
      final now = DateTime.now();
      final airDate = now.add(const Duration(days: 5));

      final series = Series(
        guid: 1,
        tvdbId: 123,
        title: 'Test Series',
        sortTitle: 'test series',
        monitored: true,
        status: SeriesStatus.continuing,
        seriesType: SeriesType.standard,
        added: now,
        images: [],
        seasons: [],
        tags: [],
        genres: [],
        year: 2023,
        runtime: 45,
      );

      final episode = Episode(
        id: 1,
        episodeNumber: 1,
        seasonNumber: 1,
        title: 'Test Episode',
        seriesId: 1,
        hasFile: false,
        monitored: true,
        airDateUtc: airDate,
        series: series,
      );

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(mockMovieRepository),
          seriesRepositoryProvider.overrideWithValue(mockSeriesRepository),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockMovieRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => []);

      when(() => mockSeriesRepository.getCalendar(
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => [episode]);

      await container.read(calendarProvider.future);

      final events = container.read(calendarProvider).value!;

      expect(events.length, 1);
      expect(events.first.type, CalendarEventType.episode);
      expect(events.first.isEpisode, true);
    });
  });
}
