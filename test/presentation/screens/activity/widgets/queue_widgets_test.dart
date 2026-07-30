import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/core/utils/formatters.dart';
import 'package:arrmate/presentation/screens/activity/widgets/queue_list_item.dart';
import 'package:arrmate/presentation/screens/activity/widgets/queue_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueueListItem', () {
    testWidgets('Deve exibir metadados reais e total agrupado', (tester) async {
      // Given
      final item = _queueItem(taskGroupCount: 2);

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: QueueListItem(item: item)),
          ),
        ),
      );

      // Then
      expect(
        find.text('WEBDL-2160p · English · TORRENT · Transmission'),
        findsOneWidget,
      );
      expect(find.text('2 tasks'), findsOneWidget);
    });

    testWidgets('Deve exibir os metadados completos no detalhe', (
      tester,
    ) async {
      // Given
      final item = _queueItem();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: QueueListItem(item: item)),
          ),
        ),
      );

      // When
      await tester.tap(find.byType(QueueListItem));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('H.265'), findsWidgets);
      expect(find.text('+25'), findsWidgets);
      expect(find.text('TorrentDay (Prowlarr)'), findsOneWidget);
      expect(find.text('Transmission'), findsWidgets);
      expect(
        find.text(formatDate(DateTime.utc(2024, 1, 2).toLocal())),
        findsOneWidget,
      );
    });
  });

  group('QueueOptionsSheet', () {
    testWidgets('Deve aplicar filtros e ordenação escolhidos', (tester) async {
      // Given
      QueueQuery? appliedQuery;
      final item = _queueItem();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return QueueOptionsSheet(
                          items: [item],
                          instances: const [],
                          query: const QueueQuery(),
                          onApply: (query) => appliedQuery = query,
                        );
                      },
                    );
                  },
                  child: const Text('Open options'),
                );
              },
            ),
          ),
        ),
      );

      // When
      await tester.tap(find.text('Open options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Problems only'));
      await tester.scrollUntilVisible(
        find.text('Title'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Title'));
      await tester.scrollUntilVisible(
        find.text('Ascending'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Ascending'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Then
      expect(appliedQuery?.issuesOnly, isTrue);
      expect(appliedQuery?.sortField, QueueSortField.title);
      expect(appliedQuery?.ascending, isTrue);
      expect(find.text('Instance'), findsNothing);
    });
  });
}

QueueItem _queueItem({int taskGroupCount = 1}) {
  return QueueItem(
    id: 1,
    title: 'South Park',
    status: QueueStatus.downloading,
    trackedDownloadStatus: 'ok',
    trackedDownloadState: 'downloading',
    protocol: 'torrent',
    downloadClient: 'Transmission',
    indexer: 'TorrentDay (Prowlarr)',
    added: DateTime.utc(2024, 1, 2),
    quality: const MediaQuality(
      quality: QualityInfo(
        id: 18,
        name: 'WEBDL-2160p',
        source: 'webdl',
        resolution: 2160,
      ),
      revision: 1,
    ),
    languages: const [MediaLanguage(id: 1, name: 'English')],
    customFormats: const [MediaCustomFormat(id: 3, name: 'H.265')],
    customFormatScore: 25,
    size: 1000,
    sizeleft: 500,
    taskGroupCount: taskGroupCount,
  );
}
