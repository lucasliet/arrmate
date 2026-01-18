import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/providers/manual_import_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManualImportState', () {
    test('copyWith creates new state with updated fields', () {
      // Given
      final originalState = ManualImportState(
        files: [_createImportableFile(id: 1, name: 'file1.mkv')],
        isLoading: false,
      );

      // When
      final updatedState = originalState.copyWith(isLoading: true);

      // Then
      expect(updatedState.isLoading, true);
      expect(updatedState.files, originalState.files);
    });

    test('copyWith preserves original values when not specified', () {
      // Given
      final originalState = ManualImportState(
        files: [_createImportableFile(id: 1, name: 'file1.mkv')],
        isLoading: true,
        error: 'Some error',
      );

      // When
      final updatedState = originalState.copyWith(isLoading: false);

      // Then
      expect(updatedState.isLoading, false);
      expect(updatedState.error, 'Some error');
      expect(updatedState.files.length, 1);
    });
  });

  group('ImportableFile copyWith', () {
    test('copyWith updates series field', () {
      // Given
      final file = _createImportableFile(id: 1, name: 'episode.mkv');
      final series = _createSeries(id: 100, title: 'Breaking Bad');

      // When
      final updatedFile = file.copyWith(series: series);

      // Then
      expect(updatedFile.series?.title, 'Breaking Bad');
      expect(updatedFile.id, 1);
      expect(updatedFile.name, 'episode.mkv');
    });

    test('copyWith updates episodes field', () {
      // Given
      final file = _createImportableFile(id: 1, name: 'episode.mkv');
      final episodes = [
        _createEpisode(id: 1, seasonNumber: 1, episodeNumber: 1),
        _createEpisode(id: 2, seasonNumber: 1, episodeNumber: 2),
      ];

      // When
      final updatedFile = file.copyWith(episodes: episodes);

      // Then
      expect(updatedFile.episodes?.length, 2);
      expect(updatedFile.episodes?.first.episodeNumber, 1);
    });

    test('toJson includes series when present', () {
      // Given
      final series = _createSeries(id: 100, title: 'Breaking Bad');
      final file = _createImportableFile(
        id: 1,
        name: 'file.mkv',
      ).copyWith(series: series);

      // When
      final json = file.toJson();

      // Then
      expect(json.containsKey('series'), true);
      expect((json['series'] as Map)['title'], 'Breaking Bad');
    });

    test('toJson includes episodes when present', () {
      // Given
      final episodes = [
        _createEpisode(id: 1, seasonNumber: 1, episodeNumber: 1),
      ];
      final file = _createImportableFile(
        id: 1,
        name: 'file.mkv',
      ).copyWith(episodes: episodes);

      // When
      final json = file.toJson();

      // Then
      expect(json.containsKey('episodes'), true);
      expect((json['episodes'] as List).length, 1);
    });
  });
}

ImportableFile _createImportableFile({required int id, required String name}) {
  return ImportableFile(id: id, name: name, size: 1024 * 1024 * 500);
}

Series _createSeries({required int id, required String title}) {
  return Series(
    guid: id,
    title: title,
    sortTitle: title.toLowerCase(),
    tvdbId: 12345,
    status: SeriesStatus.continuing,
    seriesType: SeriesType.standard,
    year: 2020,
    added: DateTime.now(),
  );
}

Episode _createEpisode({
  required int id,
  required int seasonNumber,
  required int episodeNumber,
}) {
  return Episode(
    id: id,
    seriesId: 1,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
    title: 'Episode $episodeNumber',
  );
}
