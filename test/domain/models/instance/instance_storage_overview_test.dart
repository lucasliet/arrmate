import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstanceDiskSpace', () {
    test('should parse storage values and calculate used space', () {
      // Given
      final json = {
        'path': '/mnt/media/',
        'label': 'Media',
        'freeSpace': 300,
        'totalSpace': 1000,
      };

      // When
      final diskSpace = InstanceDiskSpace.fromJson(json);

      // Then
      expect(diskSpace.displayLabel, 'Media');
      expect(diskSpace.freeSpace, 300);
      expect(diskSpace.totalSpace, 1000);
      expect(diskSpace.usedSpace, 700);
      expect(diskSpace.usedFraction, 0.7);
    });

    test('should use the trimmed path when label is empty', () {
      // Given
      final json = {
        'path': '/mnt/media/',
        'label': '',
        'freeSpace': 2000.0,
        'totalSpace': 1000,
      };

      // When
      final diskSpace = InstanceDiskSpace.fromJson(json);

      // Then
      expect(diskSpace.displayLabel, '/mnt/media');
      expect(diskSpace.usedSpace, 0);
      expect(diskSpace.usedFraction, 0);
    });
  });

  group('InstanceLibraryStatistics', () {
    test('should summarize movie count and total size', () {
      // Given
      final movies = [_movie(1, 1000), _movie(2, 2500), _movie(3, null)];

      // When
      final statistics = InstanceLibraryStatistics.fromMovies(movies);

      // Then
      expect(statistics.movieCount, 3);
      expect(statistics.seriesCount, 0);
      expect(statistics.episodeCount, 0);
      expect(statistics.sizeOnDisk, 3500);
    });

    test('should summarize series, episode files, and total size', () {
      // Given
      final series = [
        _series(1, episodeFileCount: 8, sizeOnDisk: 4000),
        _series(2, episodeFileCount: 12, sizeOnDisk: 6000),
      ];

      // When
      final statistics = InstanceLibraryStatistics.fromSeries(series);

      // Then
      expect(statistics.movieCount, 0);
      expect(statistics.seriesCount, 2);
      expect(statistics.episodeCount, 20);
      expect(statistics.sizeOnDisk, 10000);
    });
  });
}

Movie _movie(int id, int? sizeOnDisk) {
  return Movie(
    guid: id,
    tmdbId: id,
    title: 'Movie $id',
    sortTitle: 'Movie $id',
    year: 2026,
    runtime: 120,
    status: MovieStatus.released,
    isAvailable: true,
    minimumAvailability: MovieStatus.released,
    monitored: true,
    qualityProfileId: 1,
    sizeOnDisk: sizeOnDisk,
    added: DateTime(2026),
  );
}

Series _series(
  int id, {
  required int episodeFileCount,
  required int sizeOnDisk,
}) {
  return Series(
    guid: id,
    title: 'Series $id',
    sortTitle: 'Series $id',
    tvdbId: id,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2026,
    added: DateTime(2026),
    statistics: SeriesStatistics(
      sizeOnDisk: sizeOnDisk,
      seasonCount: 1,
      episodeCount: episodeFileCount,
      episodeFileCount: episodeFileCount,
      totalEpisodeCount: episodeFileCount,
      percentOfEpisodes: 100,
    ),
  );
}
