import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildQueueView', () {
    test('Deve filtrar por instância, protocolo, cliente e problemas', () {
      // Given
      final items = [
        _queueItem(
          id: 1,
          instanceId: 'radarr-home',
          protocol: 'torrent',
          downloadClient: 'Transmission',
        ),
        _queueItem(
          id: 2,
          instanceId: 'sonarr-home',
          protocol: 'torrent',
          downloadClient: 'Transmission',
          hasIssue: true,
        ),
        _queueItem(
          id: 3,
          instanceId: 'sonarr-home',
          protocol: 'usenet',
          downloadClient: 'SABnzbd',
          hasIssue: true,
        ),
      ];
      const query = QueueQuery(
        instanceId: 'sonarr-home',
        protocol: 'TORRENT',
        downloadClient: 'transmission',
        issuesOnly: true,
      );

      // When
      final view = buildQueueView(items, query);

      // Then
      expect(view.items.map((item) => item.id), [2]);
      expect(view.problemCount, 2);
    });

    test('Deve ordenar pelo título em ambas as direções', () {
      // Given
      final items = [
        _queueItem(id: 1, title: 'Zulu'),
        _queueItem(id: 2, title: 'alpha'),
        _queueItem(id: 3, title: 'Bravo'),
      ];

      // When
      final ascending = buildQueueView(
        items,
        const QueueQuery(sortField: QueueSortField.title, ascending: true),
      );
      final descending = buildQueueView(
        items,
        const QueueQuery(sortField: QueueSortField.title, ascending: false),
      );

      // Then
      expect(ascending.items.map((item) => item.id), [2, 3, 1]);
      expect(descending.items.map((item) => item.id), [1, 3, 2]);
    });

    test('Deve ordenar por data mantendo itens sem data ao final', () {
      // Given
      final items = [
        _queueItem(id: 1, added: DateTime.utc(2024, 1, 2)),
        _queueItem(id: 2),
        _queueItem(id: 3, added: DateTime.utc(2024, 1, 1)),
      ];

      // When
      final ascending = buildQueueView(
        items,
        const QueueQuery(sortField: QueueSortField.added, ascending: true),
      );
      final descending = buildQueueView(
        items,
        const QueueQuery(sortField: QueueSortField.added, ascending: false),
      );

      // Then
      expect(ascending.items.map((item) => item.id), [3, 1, 2]);
      expect(descending.items.map((item) => item.id), [1, 3, 2]);
    });

    test('Deve agrupar registros da mesma tarefa na mesma instância', () {
      // Given
      final items = [
        _queueItem(
          id: 10,
          instanceId: 'sonarr-home',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
        ),
        _queueItem(
          id: 11,
          instanceId: 'sonarr-home',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
        ),
      ];

      // When
      final view = buildQueueView(items, const QueueQuery());

      // Then
      expect(view.items, hasLength(1));
      expect(view.items.single.taskGroupCount, 2);
    });

    test('Não deve colidir tarefas idênticas de instâncias diferentes', () {
      // Given
      final items = [
        _queueItem(
          id: 42,
          instanceId: 'sonarr-home',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
        ),
        _queueItem(
          id: 42,
          instanceId: 'sonarr-remote',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
        ),
      ];

      // When
      final view = buildQueueView(items, const QueueQuery());

      // Then
      expect(view.items, hasLength(2));
      expect(
        view.items.map((item) => item.instanceId),
        containsAll(['sonarr-home', 'sonarr-remote']),
      );
    });

    test('Deve contar problemas únicos após agrupamento seguro', () {
      // Given
      final items = [
        _queueItem(
          id: 10,
          instanceId: 'sonarr-home',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
          hasIssue: true,
        ),
        _queueItem(
          id: 11,
          instanceId: 'sonarr-home',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
          hasIssue: true,
        ),
        _queueItem(
          id: 10,
          instanceId: 'sonarr-remote',
          downloadId: 'download-1',
          title: 'Series.S01.1080p',
          seasonNumber: 1,
          size: 1000,
          hasIssue: true,
        ),
      ];

      // When
      final view = buildQueueView(items, const QueueQuery());

      // Then
      expect(view.items, hasLength(2));
      expect(view.problemCount, 2);
    });
  });
}

QueueItem _queueItem({
  required int id,
  String instanceId = 'default',
  String title = 'Queue item',
  String protocol = 'torrent',
  String? downloadClient,
  String? downloadId,
  int? seasonNumber,
  int? size,
  DateTime? added,
  bool hasIssue = false,
}) {
  return QueueItem(
    id: id,
    instanceId: instanceId,
    instanceType: InstanceType.sonarr,
    title: title,
    protocol: protocol,
    downloadClient: downloadClient,
    downloadId: downloadId,
    seasonNumber: seasonNumber,
    size: size,
    sizeleft: 0,
    added: added,
    status: hasIssue ? QueueStatus.warning : QueueStatus.downloading,
    trackedDownloadStatus: hasIssue ? 'warning' : 'ok',
  );
}
