import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
