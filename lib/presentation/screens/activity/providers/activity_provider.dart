import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';

typedef _QueuePageLoader = Future<QueueItems> Function(int page, int pageSize);

// Queue Provider
/// Provider for fetching and managing the download queue, auto-refreshes every 5 seconds.
final queueProvider =
    AsyncNotifierProvider.autoDispose<QueueNotifier, List<QueueItem>>(
      QueueNotifier.new,
    );

/// Notifier to manage the download queue state.
class QueueNotifier extends AutoDisposeAsyncNotifier<List<QueueItem>> {
  Timer? _timer;

  @override
  Future<List<QueueItem>> build() async {
    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    ref.onDispose(() => _timer?.cancel());

    return _fetchQueue();
  }

  Future<List<QueueItem>> _fetchQueue() async {
    final radarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    );
    final sonarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    );
    final requests = <Future<List<QueueItem>>>[];

    for (final instance in radarrInstances) {
      final repository = ref.watch(
        movieRepositoryForInstanceProvider(instance),
      );
      requests.add(
        _fetchInstanceQueue(
          instance,
          (page, pageSize) =>
              repository.getQueue(page: page, pageSize: pageSize),
        ),
      );
    }

    for (final instance in sonarrInstances) {
      final repository = ref.watch(
        seriesRepositoryForInstanceProvider(instance),
      );
      requests.add(
        _fetchInstanceQueue(
          instance,
          (page, pageSize) =>
              repository.getQueue(page: page, pageSize: pageSize),
        ),
      );
    }

    final items = (await Future.wait(
      requests,
    )).expand((items) => items).toList();

    items.sort((a, b) {
      if (a.estimatedCompletionTime == null &&
          b.estimatedCompletionTime == null) {
        return 0;
      }
      if (a.estimatedCompletionTime == null) {
        return 1;
      }
      if (b.estimatedCompletionTime == null) {
        return -1;
      }
      return a.estimatedCompletionTime!.compareTo(b.estimatedCompletionTime!);
    });

    return items;
  }

  Future<List<QueueItem>> _fetchInstanceQueue(
    Instance instance,
    _QueuePageLoader loadPage,
  ) async {
    final items = <QueueItem>[];
    var page = 1;

    try {
      while (true) {
        final queue = await loadPage(page, ApiConstants.queuePageSize);
        items.addAll(
          queue.records.map(
            (item) => item.copyWith(
              instanceId: instance.id,
              instanceType: instance.type,
            ),
          ),
        );
        if (items.length >= queue.totalRecords || queue.records.isEmpty) {
          return items;
        }
        page++;
      }
    } catch (error, stackTrace) {
      logger.error(
        '[QueueProvider] Failed to fetch queue for instance ${instance.id}',
        error,
        stackTrace,
      );
      return items;
    }
  }

  /// Manually refreshes the queue.
  Future<void> refresh() async {
    // Silent refresh if already loaded?
    // Using ref.invalidateSelf() triggers loading state. W
    // We might want to keep previous state while updating for polling.
    // For now, standard invalidate.
    if (state.isLoading) return;

    // We can manually update state to new value to avoid loading flicker
    state = await AsyncValue.guard(() => _fetchQueue());
  }

  /// Removes an item from the queue with optional parameters.
  Future<bool> removeQueueItem(
    QueueItem item, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  }) async {
    final instanceId = item.instanceId;
    final instanceType = item.instanceType;
    if (instanceId == null || instanceType == null) {
      throw StateError('Queue item origin is missing');
    }

    final instance = ref
        .read(instancesByTypeProvider(instanceType))
        .where((candidate) => candidate.id == instanceId)
        .firstOrNull;
    if (instance == null) {
      throw StateError('Queue item instance is no longer configured');
    }

    switch (instance.type) {
      case InstanceType.radarr:
        await ref
            .read(movieRepositoryForInstanceProvider(instance))
            .deleteQueueItem(
              item.id,
              removeFromClient: removeFromClient,
              blocklist: blocklist,
              skipRedownload: skipRedownload,
            );
      case InstanceType.sonarr:
        await ref
            .read(seriesRepositoryForInstanceProvider(instance))
            .deleteQueueItem(
              item.id,
              removeFromClient: removeFromClient,
              blocklist: blocklist,
              skipRedownload: skipRedownload,
            );
      case InstanceType.qbittorrent:
        throw StateError('qBittorrent items are not part of the Arr queue');
    }

    await refresh();
    return true;
  }
}

// History Provider (Placeholder for now, usually paginated)
final historyProvider = FutureProvider.autoDispose<List<HistoryItem>>((
  ref,
) async {
  // History API is usually /history
  // Not yet fully implemented in repositories?
  return [];
});

class HistoryItem {
  // Skeleton
}
