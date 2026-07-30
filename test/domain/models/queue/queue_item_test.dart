import 'dart:convert';
import 'dart:io';

import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueueItem fromJson', () {
    test('Deve decodificar os metadados reais retornados pelo Radarr', () {
      // Given
      final json = _loadFixture('ruddarr_radarr_queue_record.json');

      // When
      final queueItem = QueueItem.fromJson(json);

      // Then
      expect(queueItem.added, DateTime.utc(2023, 5, 24, 21, 28, 21));
      expect(queueItem.quality?.quality.name, 'WEBDL-2160p');
      expect(queueItem.languages.single.name, 'English');
      expect(queueItem.customFormats.single.name, 'H.265');
      expect(queueItem.customFormatScore, 0);
      expect(queueItem.indexer, 'TorrentDay (Prowlarr)');
      expect(queueItem.protocol, 'torrent');
      expect(queueItem.downloadClient, 'Download Station');
      expect(queueItem.sizeleft, 5870368313);
      expect(queueItem.hasIssue, isFalse);
    });

    test('Deve decodificar os metadados reais retornados pelo Sonarr', () {
      // Given
      final json = _loadFixture('ruddarr_sonarr_queue_record.json');

      // When
      final queueItem = QueueItem.fromJson(json);

      // Then
      expect(queueItem.added, DateTime.utc(2024, 5, 24, 15, 37, 42));
      expect(queueItem.quality?.quality.name, 'SDTV');
      expect(queueItem.languages.single.name, 'English');
      expect(queueItem.customFormats, isEmpty);
      expect(queueItem.customFormatScore, 0);
      expect(queueItem.indexer, 'EZTV (Prowlarr)');
      expect(queueItem.downloadClient, 'Transmission');
      expect(queueItem.hasIssue, isTrue);
    });
  });

  group('QueueItem needsManualImport', () {
    test(
      'Deve retornar true quando downloadId está presente e status é warning com importPending',
      () {
        final queueItem = QueueItem(
          id: 1,
          movieId: 100,
          title: 'Test Movie',
          size: 1000000,
          sizeleft: 0,
          status: QueueStatus.warning,
          protocol: 'usenet',
          downloadId: 'download123',
          trackedDownloadStatus: 'warning',
          trackedDownloadState: 'importPending',
        );

        expect(queueItem.needsManualImport, true);
      },
    );

    test(
      'Deve retornar true quando downloadId está presente e status é warning com importBlocked',
      () {
        final queueItem = QueueItem(
          id: 1,
          movieId: 100,
          title: 'Test Movie',
          size: 1000000,
          sizeleft: 0,
          status: QueueStatus.warning,
          protocol: 'usenet',
          downloadId: 'download123',
          trackedDownloadStatus: 'warning',
          trackedDownloadState: 'importBlocked',
        );

        expect(queueItem.needsManualImport, true);
      },
    );

    test('Deve retornar false quando downloadId está ausente', () {
      final queueItem = QueueItem(
        id: 1,
        movieId: 100,
        title: 'Test Movie',
        size: 1000000,
        sizeleft: 0,
        status: QueueStatus.warning,
        protocol: 'usenet',
        downloadId: null,
        trackedDownloadStatus: 'warning',
        trackedDownloadState: 'importPending',
      );

      expect(queueItem.needsManualImport, false);
    });

    test('Deve retornar false quando trackedDownloadStatus não é warning', () {
      final queueItem = QueueItem(
        id: 1,
        movieId: 100,
        title: 'Test Movie',
        size: 1000000,
        sizeleft: 0,
        status: QueueStatus.downloading,
        protocol: 'usenet',
        downloadId: 'download123',
        trackedDownloadStatus: 'ok',
        trackedDownloadState: 'importPending',
      );

      expect(queueItem.needsManualImport, false);
    });

    test(
      'Deve retornar false quando trackedDownloadState não é importPending nem importBlocked',
      () {
        final queueItem = QueueItem(
          id: 1,
          movieId: 100,
          title: 'Test Movie',
          size: 1000000,
          sizeleft: 0,
          status: QueueStatus.warning,
          protocol: 'usenet',
          downloadId: 'download123',
          trackedDownloadStatus: 'warning',
          trackedDownloadState: 'downloading',
        );

        expect(queueItem.needsManualImport, false);
      },
    );

    test('Deve retornar false quando todos os campos estão ausentes', () {
      final queueItem = QueueItem(
        id: 1,
        movieId: 100,
        title: 'Test Movie',
        size: 1000000,
        sizeleft: 0,
        status: QueueStatus.downloading,
        protocol: 'usenet',
      );

      expect(queueItem.needsManualImport, false);
    });
  });
}

Map<String, dynamic> _loadFixture(String name) {
  final content = File('test/fixtures/queue/$name').readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}
