import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/movie_repository.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/screens/activity/providers/torrent_import_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSeriesRepository extends Mock implements SeriesRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const <ImportableFile>[]);
  });

  group('TorrentImportController', () {
    test('should tie a movie import to the torrent it came from', () async {
      // Given
      // Radarr records the qBittorrent infohash uppercased and looks it up
      // case-sensitively, so a lowercase id would find no tracked download and
      // the import would land unrelated to the torrent.
      final repository = MockMovieRepository();
      when(
        () =>
            repository.manualImport(any(), copyFiles: any(named: 'copyFiles')),
      ).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [movieRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      // When
      await container.read(torrentImportControllerProvider(true)).importFiles(
        const [_file],
        torrentHash: 'aabbccdd',
      );

      // Then
      final captured = verify(
        () => repository.manualImport(
          captureAny(),
          copyFiles: captureAny(named: 'copyFiles'),
        ),
      ).captured;
      final files = captured.first as List<ImportableFile>;
      expect(files.single.downloadId, 'AABBCCDD');
    });

    test('should copy the files instead of letting them be moved', () async {
      // Given
      // The torrent is still seeding what it just handed over.
      final repository = MockMovieRepository();
      when(
        () =>
            repository.manualImport(any(), copyFiles: any(named: 'copyFiles')),
      ).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [movieRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      // When
      await container.read(torrentImportControllerProvider(true)).importFiles(
        const [_file],
        torrentHash: 'aabbccdd',
      );

      // Then
      verify(() => repository.manualImport(any(), copyFiles: true)).called(1);
    });

    test('should tie a series import to the torrent as well', () async {
      // Given
      final repository = MockSeriesRepository();
      when(
        () =>
            repository.manualImport(any(), copyFiles: any(named: 'copyFiles')),
      ).thenAnswer((_) async {});
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      // When
      await container.read(torrentImportControllerProvider(false)).importFiles(
        const [_file],
        torrentHash: 'aabbccdd',
      );

      // Then
      final captured = verify(
        () => repository.manualImport(
          captureAny(),
          copyFiles: captureAny(named: 'copyFiles'),
        ),
      ).captured;
      expect(
        (captured.first as List<ImportableFile>).single.downloadId,
        'AABBCCDD',
      );
      expect(captured.last, isTrue);
    });
  });
}

const _file = ImportableFile(id: 1, name: 'Movie.mkv', size: 1024);
