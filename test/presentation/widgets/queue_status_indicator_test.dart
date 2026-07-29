import 'package:arrmate/domain/models/models.dart';
import 'package:arrmate/presentation/screens/activity/providers/activity_provider.dart';
import 'package:arrmate/presentation/widgets/queue_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'QueueStatusIndicator should render a badge when the movie is queued',
    (tester) async {
      final movieId = 42;
      final queueItem = QueueItem(
        id: 1,
        movieId: movieId,
        title: 'Queued movie',
        status: QueueStatus.downloading,
        protocol: 'torrent',
        sizeleft: 100,
        instanceId: 'inst-a',
        instanceType: InstanceType.radarr,
      );
      final container = ProviderContainer(
        overrides: [
          queueProvider.overrideWith(() => _FakeQueueNotifier([queueItem])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: QueueStatusIndicator(
                instanceType: InstanceType.radarr,
                instanceId: 'inst-a',
                movieId: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.downloading), findsOneWidget);
    },
  );

  testWidgets('QueueStatusIndicator should hide when the movie is not queued', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        queueProvider.overrideWith(() => _FakeQueueNotifier(const [])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: QueueStatusIndicator(
              instanceType: InstanceType.radarr,
              instanceId: 'inst-a',
              movieId: 99,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.downloading), findsNothing);
  });

  testWidgets(
    'QueueStatusIndicator should not cross-report the same id across instances',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          queueProvider.overrideWith(
            () => _FakeQueueNotifier([
              QueueItem(
                id: 1,
                movieId: 5,
                title: 'Movie on instance B',
                status: QueueStatus.downloading,
                protocol: 'torrent',
                sizeleft: 100,
                instanceId: 'inst-b',
                instanceType: InstanceType.radarr,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: QueueStatusIndicator(
                instanceType: InstanceType.radarr,
                instanceId: 'inst-a',
                movieId: 5,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.downloading), findsNothing);
    },
  );

  testWidgets(
    'QueueStatusIndicator should show failed icon over downloading when both '
    'exist for the same media',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          queueProvider.overrideWith(
            () => _FakeQueueNotifier([
              QueueItem(
                id: 1,
                movieId: 7,
                title: 'Downloading copy',
                status: QueueStatus.downloading,
                protocol: 'torrent',
                sizeleft: 100,
                instanceId: 'inst-a',
                instanceType: InstanceType.radarr,
              ),
              QueueItem(
                id: 2,
                movieId: 7,
                title: 'Failed copy',
                status: QueueStatus.failed,
                protocol: 'torrent',
                sizeleft: 0,
                instanceId: 'inst-a',
                instanceType: InstanceType.radarr,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: QueueStatusIndicator(
                instanceType: InstanceType.radarr,
                instanceId: 'inst-a',
                movieId: 7,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.downloading), findsNothing);
    },
  );
}

class _FakeQueueNotifier extends QueueNotifier {
  final List<QueueItem> _items;

  _FakeQueueNotifier(this._items);

  @override
  Future<List<QueueItem>> build() async => _items;
}
