import 'package:arrmate/core/utils/discovery_results.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('movie discovery results', () {
    test('should hide explicit library matches without using added date', () {
      // Given
      final existing = _movie(
        title: 'Existing',
        tmdbId: 1,
        guid: 10,
        year: 2020,
        rating: 5,
      );
      final lookup = _movie(title: 'Lookup', tmdbId: 2, year: 2021, rating: 6);

      // When
      final results = prepareMovieDiscoveryResults(
        [existing, lookup],
        sort: DiscoverySortOption.relevance,
        hideExisting: true,
      );

      // Then
      expect(results, [lookup]);
      expect(lookup.added.year, 2024);
    });

    test('should order movies by latest year and rating', () {
      // Given
      final olderRated = _movie(
        title: 'Older',
        tmdbId: 1,
        year: 2020,
        rating: 9,
      );
      final newer = _movie(title: 'Newer', tmdbId: 2, year: 2024, rating: 5);

      // When
      final latest = prepareMovieDiscoveryResults(
        [olderRated, newer],
        sort: DiscoverySortOption.latest,
        hideExisting: false,
      );
      final rated = prepareMovieDiscoveryResults(
        [olderRated, newer],
        sort: DiscoverySortOption.rating,
        hideExisting: false,
      );

      // Then
      expect(latest.first, newer);
      expect(rated.first, olderRated);
    });
  });

  group('series discovery results', () {
    test('should preserve relevance and sort by rating when requested', () {
      // Given
      final first = _series(title: 'First', tvdbId: 1, rating: 5);
      final second = _series(title: 'Second', tvdbId: 2, rating: 9);

      // When
      final relevant = prepareSeriesDiscoveryResults(
        [first, second],
        sort: DiscoverySortOption.relevance,
        hideExisting: false,
      );
      final rated = prepareSeriesDiscoveryResults(
        [first, second],
        sort: DiscoverySortOption.rating,
        hideExisting: false,
      );

      // Then
      expect(relevant, [first, second]);
      expect(rated, [second, first]);
    });
  });
}

Movie _movie({
  required String title,
  required int tmdbId,
  required int year,
  required double rating,
  int? guid,
}) {
  return Movie(
    guid: guid,
    tmdbId: tmdbId,
    title: title,
    sortTitle: title,
    year: year,
    runtime: 100,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: false,
    qualityProfileId: 0,
    added: DateTime(2024),
    ratings: MovieRatings(tmdb: MovieRating(votes: 1, value: rating)),
  );
}

Series _series({
  required String title,
  required int tvdbId,
  required double rating,
}) {
  return Series(
    title: title,
    sortTitle: title,
    tvdbId: tvdbId,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2024,
    added: DateTime(2024),
    ratings: SeriesRatings(votes: 1, value: rating),
  );
}
