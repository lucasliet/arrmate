import 'package:arrmate/data/api/qbittorrent_service.dart';
import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/domain/repositories/series_repository.dart';
import 'package:arrmate/presentation/providers/data_providers.dart';
import 'package:arrmate/presentation/providers/instances_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_metadata_provider.dart';
import 'package:arrmate/presentation/screens/series/providers/series_provider.dart';
import 'package:arrmate/presentation/shared/providers/media_torrents_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeriesRepository extends Mock implements SeriesRepository {}

class MockQBittorrentService extends Mock implements QBittorrentService {}

void main() {
  group('SeriesMetadataController.refreshAfterPurge', () {
    late MockSeriesRepository repository;
    late MockQBittorrentService qbittorrent;
    late ProviderContainer container;

    setUp(() {
      repository = MockSeriesRepository();
      qbittorrent = MockQBittorrentService();
      when(() => repository.getSeriesFiles(3)).thenAnswer((_) async => []);
      when(
        () => repository.getSeriesHistory(3),
      ).thenAnswer((_) async => [_grabbed(downloadId: 'AABB', episodeId: 42)]);
      when(
        () => repository.getSeriesById(3),
      ).thenAnswer((_) async => _series(id: 3));
      when(
        () => repository.getQueue(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          sortKey: any(named: 'sortKey'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer(
        (_) async => const QueueItems(
          page: 1,
          pageSize: 100,
          sortKey: 'timeleft',
          sortDirection: 'ascending',
          totalRecords: 0,
          records: [],
        ),
      );
      when(qbittorrent.getTorrents).thenAnswer((_) async => []);
      container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(repository),
          qbittorrentServiceProvider.overrideWithValue(qbittorrent),
          currentSonarrInstanceProvider.overrideWithValue(
            Instance(
              id: 'sonarr-home',
              type: InstanceType.sonarr,
              label: 'sonarr-home',
              url: 'https://sonarr.example.com',
              apiKey: 'key',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('should make files, details, history and torrents load again', () async {
      // Given every provider already holds a pre-purge result
      for (final provider in [
        seriesFilesProvider(3),
        seriesDetailsProvider(3),
        seriesHistoryProvider(3),
      ]) {
        container.listen(provider, (_, _) {});
      }
      container.listen(seriesTorrentsProvider(3), (_, _) {});
      await container.read(seriesFilesProvider(3).future);
      await container.read(seriesDetailsProvider(3).future);
      await container.read(seriesHistoryProvider(3).future);
      await container.read(seriesTorrentsProvider(3).future);

      // When a season purge finishes
      container.read(seriesMetadataControllerProvider(3)).refreshAfterPurge([
        1,
      ]);
      await container.read(seriesFilesProvider(3).future);
      await container.read(seriesDetailsProvider(3).future);
      await container.read(seriesHistoryProvider(3).future);
      await container.read(seriesTorrentsProvider(3).future);

      // Then each one asked its source again, so the screens show post-purge data
      verify(() => repository.getSeriesFiles(3)).called(2);
      verify(() => repository.getSeriesById(3)).called(2);
      // The history is read by its own provider and by the torrents lookup.
      verify(() => repository.getSeriesHistory(3)).called(4);
      verify(qbittorrent.getTorrents).called(2);
    });

    test('should still refresh when the controller outlives its autoDispose '
        'provider', () async {
      // Given the screens read the controller before the confirmation
      // dialogs and the purge, and nothing keeps its provider alive
      final controller = container.read(seriesMetadataControllerProvider(3));
      container.listen(seriesFilesProvider(3), (_, _) {});
      await container.read(seriesFilesProvider(3).future);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // When the purge finishes much later
      controller.refreshAfterPurge([1]);
      await container.read(seriesFilesProvider(3).future);

      // Then the series is reloaded instead of the call throwing
      verify(() => repository.getSeriesFiles(3)).called(2);
    });

    test('should not touch the data of another series', () async {
      // Given
      when(() => repository.getSeriesFiles(4)).thenAnswer((_) async => []);
      container.listen(seriesFilesProvider(4), (_, _) {});
      await container.read(seriesFilesProvider(4).future);

      // When
      container.read(seriesMetadataControllerProvider(3)).refreshAfterPurge([
        1,
        2,
      ]);
      await container.read(seriesFilesProvider(4).future);

      // Then
      verify(() => repository.getSeriesFiles(4)).called(1);
    });
  });
}

Series _series({required int id}) {
  return Series.fromJson({
    'id': id,
    'tvdbId': id,
    'title': 'Severance',
    'added': '2026-01-01T00:00:00Z',
  });
}

HistoryEvent _grabbed({required String downloadId, required int episodeId}) {
  return HistoryEvent.fromJson({
    'id': episodeId,
    'eventType': 'grabbed',
    'date': '2026-01-01T00:00:00Z',
    'sourceTitle': 'Severance.S01E01',
    'seriesId': 3,
    'episodeId': episodeId,
    'downloadId': downloadId,
    'quality': {
      'quality': {'id': 1, 'name': '1080p'},
      'revision': {'version': 1, 'real': 0},
    },
  });
}
