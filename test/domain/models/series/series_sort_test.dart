import 'package:arrmate/domain/models/series/series.dart';
import 'package:arrmate/domain/models/series/series_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesFilter', () {
    test('should match series with missing episode files', () {
      // Given
      final missing = buildSeries(episodeCount: 10, episodeFileCount: 8);
      final complete = buildSeries(episodeCount: 10, episodeFileCount: 10);

      // When
      final missingMatches = SeriesFilter.missing.filter(missing);
      final completeMatches = SeriesFilter.missing.filter(complete);

      // Then
      expect(missingMatches, isTrue);
      expect(completeMatches, isFalse);
    });

    test(
      'should match only unmonitored series without episodes as dangling',
      () {
        // Given
        final dangling = buildSeries();
        final monitored = buildSeries(monitored: true);
        final withEpisodes = buildSeries(episodeCount: 1);

        // When
        final danglingMatches = SeriesFilter.dangling.filter(dangling);
        final monitoredMatches = SeriesFilter.dangling.filter(monitored);
        final withEpisodesMatches = SeriesFilter.dangling.filter(withEpisodes);

        // Then
        expect(danglingMatches, isTrue);
        expect(monitoredMatches, isFalse);
        expect(withEpisodesMatches, isFalse);
      },
    );

    test('should handle missing statistics deterministically', () {
      // Given
      final series = buildSeries(includeStatistics: false);

      // When
      final missingMatches = SeriesFilter.missing.filter(series);
      final danglingMatches = SeriesFilter.dangling.filter(series);

      // Then
      expect(missingMatches, isFalse);
      expect(danglingMatches, isTrue);
    });
  });

  group('SeriesSort root folder filter', () {
    test('should combine the root folder and series filters', () {
      // Given
      const sort = SeriesSort(
        filter: SeriesFilter.missing,
        rootFolderPath: '/media/series/',
      );
      final matching = buildSeries(
        rootFolderPath: '/media/series',
        episodeCount: 10,
        episodeFileCount: 8,
      );
      final wrongFolder = buildSeries(
        rootFolderPath: '/media/archive',
        episodeCount: 10,
        episodeFileCount: 8,
      );
      final wrongFilter = buildSeries(
        rootFolderPath: '/media/series',
        episodeCount: 10,
        episodeFileCount: 10,
      );

      // When
      final matchingResult = sort.matches(matching);
      final wrongFolderResult = sort.matches(wrongFolder);
      final wrongFilterResult = sort.matches(wrongFilter);

      // Then
      expect(matchingResult, isTrue);
      expect(wrongFolderResult, isFalse);
      expect(wrongFilterResult, isFalse);
    });

    test('should reject a missing media root folder when one is selected', () {
      // Given
      const sort = SeriesSort(rootFolderPath: '/media/series');
      final series = buildSeries();

      // When
      final result = sort.matches(series);

      // Then
      expect(result, isFalse);
    });
  });

  group('SeriesSortOption', () {
    test(
      'should prioritize the nearest next airing and handle missing dates',
      () {
        // Given
        final sooner = buildSeries(nextAiring: DateTime.utc(2025, 1, 1));
        final later = buildSeries(nextAiring: DateTime.utc(2025, 2, 1));
        final missing = buildSeries();

        // When
        final nearestFirst = SeriesSortOption.byNextAiring.compare(
          sooner,
          later,
        );
        final missingComparison = SeriesSortOption.byNextAiring.compare(
          missing,
          sooner,
        );
        final bothMissing = SeriesSortOption.byNextAiring.compare(
          missing,
          buildSeries(),
        );

        // Then
        expect(nearestFirst, isPositive);
        expect(missingComparison, isNegative);
        expect(bothMissing, isZero);
      },
    );

    test(
      'should sort previous airings chronologically and handle missing dates',
      () {
        // Given
        final older = buildSeries(previousAiring: DateTime.utc(2024, 1, 1));
        final newer = buildSeries(previousAiring: DateTime.utc(2025, 1, 1));
        final missing = buildSeries();

        // When
        final chronological = SeriesSortOption.byPreviousAiring.compare(
          older,
          newer,
        );
        final missingComparison = SeriesSortOption.byPreviousAiring.compare(
          missing,
          older,
        );
        final bothMissing = SeriesSortOption.byPreviousAiring.compare(
          missing,
          buildSeries(),
        );

        // Then
        expect(chronological, isNegative);
        expect(missingComparison, isNegative);
        expect(bothMissing, isZero);
      },
    );
  });

  group('SeriesSort JSON', () {
    test('should round-trip new sort and filter values', () {
      // Given
      const original = SeriesSort(
        option: SeriesSortOption.byPreviousAiring,
        isAscending: true,
        filter: SeriesFilter.missing,
        rootFolderPath: '/media/series',
      );

      // When
      final restored = SeriesSort.fromJson(original.toJson());

      // Then
      expect(restored, original);
    });

    test('should load existing preferences without a root folder', () {
      // Given
      final json = {
        'option': 'bySize',
        'isAscending': true,
        'filter': 'continuing',
      };

      // When
      final restored = SeriesSort.fromJson(json);

      // Then
      expect(restored.option, SeriesSortOption.bySize);
      expect(restored.isAscending, isTrue);
      expect(restored.filter, SeriesFilter.continuing);
      expect(restored.rootFolderPath, isNull);
    });

    test('should migrate byAiring and legacy folder preferences', () {
      // Given
      final json = {
        'option': 'byAiring',
        'isAscending': false,
        'filter': 'all',
        'folder': '/media/series',
      };

      // When
      final restored = SeriesSort.fromJson(json);

      // Then
      expect(restored.option, SeriesSortOption.byNextAiring);
      expect(restored.rootFolderPath, '/media/series');
    });

    test('should migrate the legacy all folder sentinel to no filter', () {
      // Given
      final json = {
        'option': 'byAdded',
        'isAscending': false,
        'filter': 'all',
        'folder': 'all',
      };

      // When
      final restored = SeriesSort.fromJson(json);

      // Then
      expect(restored.rootFolderPath, isNull);
    });
  });
}

Series buildSeries({
  bool monitored = false,
  String? rootFolderPath,
  int episodeCount = 0,
  int episodeFileCount = 0,
  bool includeStatistics = true,
  DateTime? nextAiring,
  DateTime? previousAiring,
}) {
  return Series(
    title: 'Series',
    sortTitle: 'series',
    tvdbId: 1,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    rootFolderPath: rootFolderPath,
    year: 2025,
    added: DateTime.utc(2025),
    monitored: monitored,
    nextAiring: nextAiring,
    previousAiring: previousAiring,
    statistics: includeStatistics
        ? SeriesStatistics(
            sizeOnDisk: 0,
            seasonCount: 0,
            episodeCount: episodeCount,
            episodeFileCount: episodeFileCount,
            totalEpisodeCount: episodeCount,
            percentOfEpisodes: episodeCount == 0
                ? 0
                : episodeFileCount / episodeCount * 100,
          )
        : null,
  );
}
