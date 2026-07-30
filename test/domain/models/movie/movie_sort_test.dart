import 'package:arrmate/domain/models/movie/movie.dart';
import 'package:arrmate/domain/models/movie/movie_sort.dart';
import 'package:arrmate/domain/models/shared/media_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieFilter', () {
    test('should match wanted movies regardless of availability', () {
      // Given
      final available = buildMovie(monitored: true, isAvailable: true);
      final unavailable = buildMovie(monitored: true);

      // When
      final availableMatches = MovieFilter.wanted.filter(available);
      final unavailableMatches = MovieFilter.wanted.filter(unavailable);

      // Then
      expect(availableMatches, isTrue);
      expect(unavailableMatches, isTrue);
    });

    test('should reject downloaded or unmonitored movies from wanted', () {
      // Given
      final downloaded = buildMovie(monitored: true, grabbedAt: DateTime(2025));
      final unmonitored = buildMovie();

      // When
      final downloadedMatches = MovieFilter.wanted.filter(downloaded);
      final unmonitoredMatches = MovieFilter.wanted.filter(unmonitored);

      // Then
      expect(downloadedMatches, isFalse);
      expect(unmonitoredMatches, isFalse);
    });

    test('should match only unmonitored movies without files as dangling', () {
      // Given
      final dangling = buildMovie();
      final monitored = buildMovie(monitored: true);
      final downloaded = buildMovie(grabbedAt: DateTime(2025));

      // When
      final danglingMatches = MovieFilter.dangling.filter(dangling);
      final monitoredMatches = MovieFilter.dangling.filter(monitored);
      final downloadedMatches = MovieFilter.dangling.filter(downloaded);

      // Then
      expect(danglingMatches, isTrue);
      expect(monitoredMatches, isFalse);
      expect(downloadedMatches, isFalse);
    });

    test('should preserve missing availability semantics', () {
      // Given
      final missing = buildMovie(monitored: true, isAvailable: true);
      final unavailable = buildMovie(monitored: true);

      // When
      final missingMatches = MovieFilter.missing.filter(missing);
      final unavailableMatches = MovieFilter.missing.filter(unavailable);

      // Then
      expect(missingMatches, isTrue);
      expect(unavailableMatches, isFalse);
    });
  });

  group('MovieSort root folder filter', () {
    test('should combine the root folder and movie filters', () {
      // Given
      const sort = MovieSort(
        filter: MovieFilter.wanted,
        rootFolderPath: '/media/movies/',
      );
      final matching = buildMovie(
        monitored: true,
        rootFolderPath: '/media/movies',
      );
      final wrongFolder = buildMovie(
        monitored: true,
        rootFolderPath: '/media/archive',
      );
      final wrongFilter = buildMovie(rootFolderPath: '/media/movies');

      // When
      final matchingResult = sort.matches(matching);
      final wrongFolderResult = sort.matches(wrongFolder);
      final wrongFilterResult = sort.matches(wrongFilter);

      // Then
      expect(matchingResult, isTrue);
      expect(wrongFolderResult, isFalse);
      expect(wrongFilterResult, isFalse);
    });

    test('should accept every root folder when none is selected', () {
      // Given
      const sort = MovieSort();
      final withFolder = buildMovie(rootFolderPath: '/media/movies');
      final withoutFolder = buildMovie();

      // When
      final withFolderResult = sort.matches(withFolder);
      final withoutFolderResult = sort.matches(withoutFolder);

      // Then
      expect(withFolderResult, isTrue);
      expect(withoutFolderResult, isTrue);
    });
  });

  group('MovieSortOption', () {
    test('should sort by grabbed date and handle missing files', () {
      // Given
      final older = buildMovie(grabbedAt: DateTime.utc(2024));
      final newer = buildMovie(grabbedAt: DateTime.utc(2025));
      final missing = buildMovie();

      // When
      final chronological = MovieSortOption.byGrabbed.compare(older, newer);
      final missingComparison = MovieSortOption.byGrabbed.compare(
        missing,
        older,
      );
      final bothMissing = MovieSortOption.byGrabbed.compare(
        missing,
        buildMovie(),
      );

      // Then
      expect(chronological, isNegative);
      expect(missingComparison, isNegative);
      expect(bothMissing, isZero);
    });

    test('should sort by digital release and handle missing dates', () {
      // Given
      final older = buildMovie(digitalRelease: DateTime.utc(2024));
      final newer = buildMovie(digitalRelease: DateTime.utc(2025));
      final missing = buildMovie();

      // When
      final chronological = MovieSortOption.byRelease.compare(older, newer);
      final missingComparison = MovieSortOption.byRelease.compare(
        missing,
        older,
      );
      final bothMissing = MovieSortOption.byRelease.compare(
        missing,
        buildMovie(),
      );

      // Then
      expect(chronological, isNegative);
      expect(missingComparison, isNegative);
      expect(bothMissing, isZero);
    });
  });

  group('MovieSort JSON', () {
    test('should round-trip new sort and filter values', () {
      // Given
      const original = MovieSort(
        option: MovieSortOption.byGrabbed,
        isAscending: true,
        filter: MovieFilter.wanted,
        rootFolderPath: '/media/movies',
      );

      // When
      final restored = MovieSort.fromJson(original.toJson());

      // Then
      expect(restored, original);
    });

    test('should load existing preferences without a root folder', () {
      // Given
      final json = {
        'option': 'byRuntime',
        'isAscending': true,
        'filter': 'downloaded',
      };

      // When
      final restored = MovieSort.fromJson(json);

      // Then
      expect(restored.option, MovieSortOption.byRuntime);
      expect(restored.isAscending, isTrue);
      expect(restored.filter, MovieFilter.downloaded);
      expect(restored.rootFolderPath, isNull);
    });

    test('should migrate the legacy folder preference', () {
      // Given
      final json = {
        'option': 'byAdded',
        'isAscending': false,
        'filter': 'all',
        'folder': '/media/movies',
      };

      // When
      final restored = MovieSort.fromJson(json);

      // Then
      expect(restored.rootFolderPath, '/media/movies');
    });
  });
}

Movie buildMovie({
  bool monitored = false,
  bool isAvailable = false,
  String? rootFolderPath,
  DateTime? grabbedAt,
  DateTime? digitalRelease,
}) {
  return Movie(
    tmdbId: 1,
    title: 'Movie',
    sortTitle: 'movie',
    year: 2025,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: isAvailable,
    minimumAvailability: MovieStatus.released,
    monitored: monitored,
    qualityProfileId: 1,
    rootFolderPath: rootFolderPath,
    added: DateTime.utc(2025),
    digitalRelease: digitalRelease,
    movieFile: grabbedAt == null
        ? null
        : MediaFile(id: 1, size: 1, dateAdded: grabbedAt),
  );
}
