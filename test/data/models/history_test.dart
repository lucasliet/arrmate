import 'package:flutter_test/flutter_test.dart';

import 'package:arrmate/domain/models/shared/history.dart';

void main() {
  group('HistoryEventType', () {
    test('Converte eventos Radarr corretamente', () {
      // Given / When / Then
      expect(HistoryEventType.fromString('grabbed'), HistoryEventType.grabbed);
      expect(
        HistoryEventType.fromString('downloadFolderImported'),
        HistoryEventType.imported,
      );
      expect(
        HistoryEventType.fromString('movieFolderImported'),
        HistoryEventType.imported,
      );
      expect(
        HistoryEventType.fromString('downloadFailed'),
        HistoryEventType.failed,
      );
      expect(
        HistoryEventType.fromString('downloadIgnored'),
        HistoryEventType.ignored,
      );
      expect(
        HistoryEventType.fromString('movieFileRenamed'),
        HistoryEventType.renamed,
      );
      expect(
        HistoryEventType.fromString('movieFileDeleted'),
        HistoryEventType.deleted,
      );
    });

    test('Converte eventos Sonarr corretamente', () {
      // Given / When / Then
      expect(
        HistoryEventType.fromString('seriesFolderImported'),
        HistoryEventType.imported,
      );
      expect(
        HistoryEventType.fromString('episodeFileRenamed'),
        HistoryEventType.renamed,
      );
      expect(
        HistoryEventType.fromString('episodeFileDeleted'),
        HistoryEventType.deleted,
      );
    });

    test('Retorna unknown para valores desconhecidos', () {
      // Given / When / Then
      expect(HistoryEventType.fromString(null), HistoryEventType.unknown);
      expect(HistoryEventType.fromString('invalid'), HistoryEventType.unknown);
      expect(HistoryEventType.fromString(''), HistoryEventType.unknown);
    });

    test('Retorna labels corretos', () {
      // Given / When / Then
      expect(HistoryEventType.grabbed.label, 'Grabbed');
      expect(HistoryEventType.imported.label, 'Imported');
      expect(HistoryEventType.failed.label, 'Failed');
      expect(HistoryEventType.deleted.label, 'Deleted');
      expect(HistoryEventType.renamed.label, 'Renamed');
      expect(HistoryEventType.ignored.label, 'Ignored');
      expect(HistoryEventType.unknown.label, 'Unknown');
    });

    test('Retorna event type IDs corretos para Radarr', () {
      // Given / When / Then
      expect(HistoryEventType.grabbed.toRadarrEventType(), 1);
      expect(HistoryEventType.imported.toRadarrEventType(), 3);
      expect(HistoryEventType.failed.toRadarrEventType(), 4);
      expect(HistoryEventType.deleted.toRadarrEventType(), 6);
      expect(HistoryEventType.renamed.toRadarrEventType(), 8);
      expect(HistoryEventType.ignored.toRadarrEventType(), 9);
      expect(HistoryEventType.unknown.toRadarrEventType(), null);
    });

    test('Retorna event type IDs corretos para Sonarr', () {
      // Given / When / Then
      expect(HistoryEventType.grabbed.toSonarrEventType(), 1);
      expect(HistoryEventType.imported.toSonarrEventType(), 3);
      expect(HistoryEventType.failed.toSonarrEventType(), 4);
      expect(HistoryEventType.deleted.toSonarrEventType(), 5);
      expect(HistoryEventType.renamed.toSonarrEventType(), 6);
      expect(HistoryEventType.ignored.toSonarrEventType(), 7);
      expect(HistoryEventType.unknown.toSonarrEventType(), null);
    });
  });

  group('HistoryEvent', () {
    test('Deserializa JSON corretamente', () {
      // Given
      final json = {
        'id': 123,
        'eventType': 'grabbed',
        'date': '2026-01-01T10:00:00Z',
        'sourceTitle': 'Movie.2026.1080p.BluRay',
        'movieId': 456,
        'quality': {
          'quality': {'id': 1, 'name': '1080p'},
          'revision': {'version': 1, 'real': 0},
        },
        'languages': [
          {'id': 1, 'name': 'English'},
        ],
        'data': {'indexer': 'NZBGeek', 'downloadClient': 'SABnzbd'},
      };

      // When
      final event = HistoryEvent.fromJson(json, instanceId: 'test-instance');

      // Then
      expect(event.id, 123);
      expect(event.eventType, HistoryEventType.grabbed);
      expect(event.sourceTitle, 'Movie.2026.1080p.BluRay');
      expect(event.movieId, 456);
      expect(event.instanceId, 'test-instance');
      expect(event.indexer, 'NZBGeek');
      expect(event.downloadClient, 'SABnzbd');
      expect(event.isMovie, true);
      expect(event.isEpisode, false);
    });

    test('Deserializa evento de episódio corretamente', () {
      // Given
      final json = {
        'id': 789,
        'eventType': 'downloadFolderImported',
        'date': '2026-01-02T15:30:00Z',
        'sourceTitle': 'Series.S01E05.720p',
        'seriesId': 111,
        'episodeId': 222,
        'quality': {
          'quality': {'id': 2, 'name': '720p'},
          'revision': {'version': 1, 'real': 0},
        },
      };

      // When
      final event = HistoryEvent.fromJson(json);

      // Then
      expect(event.id, 789);
      expect(event.eventType, HistoryEventType.imported);
      expect(event.seriesId, 111);
      expect(event.episodeId, 222);
      expect(event.isMovie, false);
      expect(event.isEpisode, true);
    });

    test('Gera descrição correta para grabbed', () {
      // Given
      final json = {
        'id': 1,
        'eventType': 'grabbed',
        'date': '2026-01-01T10:00:00Z',
        'movieId': 1,
        'quality': {
          'quality': {'id': 1, 'name': '1080p'},
          'revision': {'version': 1, 'real': 0},
        },
        'data': {'indexer': 'TestIndexer', 'downloadClient': 'TestClient'},
      };
      final event = HistoryEvent.fromJson(json);

      // When
      final description = event.description;

      // Then
      expect(description, contains('grabbed'));
      expect(description, contains('TestIndexer'));
      expect(description, contains('TestClient'));
    });

    test('Gera descrição correta para deleted com reason', () {
      // Given
      final json = {
        'id': 1,
        'eventType': 'movieFileDeleted',
        'date': '2026-01-01T10:00:00Z',
        'movieId': 1,
        'quality': {
          'quality': {'id': 1, 'name': '1080p'},
          'revision': {'version': 1, 'real': 0},
        },
        'data': {'reason': 'Upgrade'},
      };
      final event = HistoryEvent.fromJson(json);

      // When
      final description = event.description;

      // Then
      expect(description, contains('upgrade'));
    });
  });

  group('HistoryPage', () {
    test('Deserializa JSON corretamente', () {
      // Given
      final json = {
        'page': 1,
        'pageSize': 25,
        'totalRecords': 100,
        'records': [
          {
            'id': 1,
            'eventType': 'grabbed',
            'date': '2026-01-01T10:00:00Z',
            'quality': {
              'quality': {'id': 1, 'name': '1080p'},
              'revision': {'version': 1, 'real': 0},
            },
          },
        ],
      };

      // When
      final page = HistoryPage.fromJson(json, instanceId: 'test');

      // Then
      expect(page.page, 1);
      expect(page.pageSize, 25);
      expect(page.totalRecords, 100);
      expect(page.records.length, 1);
      expect(page.hasMore, true);
    });

    test('Calcula hasMore corretamente', () {
      // Given
      final json = {
        'page': 4,
        'pageSize': 25,
        'totalRecords': 100,
        'records': [],
      };

      // When
      final page = HistoryPage.fromJson(json);

      // Then
      expect(page.hasMore, false); // 4*25 = 100, so no more pages
    });
  });
}
