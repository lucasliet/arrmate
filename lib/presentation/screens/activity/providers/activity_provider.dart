import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_load_failure_banner.dart';

typedef _QueuePageLoader = Future<QueueItems> Function(int page, int pageSize);

class _InstanceQueueResult {
  final List<QueueItem> items;
  final InstanceLoadFailure? failure;

  const _InstanceQueueResult({required this.items, this.failure});
}

// Queue Provider
/// Provider for fetching and managing the download queue, auto-refreshes every 5 seconds.
final queueProvider =
    AsyncNotifierProvider.autoDispose<QueueNotifier, List<QueueItem>>(
      QueueNotifier.new,
    );

/// Exposes per-instance queue failures so the UI can surface partial data
/// alongside a retry banner instead of treating it as an empty queue.
final queueFailuresProvider = Provider.autoDispose<List<InstanceLoadFailure>>((
  ref,
) {
  ref.watch(queueProvider);
  return ref.watch(queueProvider.notifier).failures;
});

/// Notifier to manage the download queue state.
class QueueNotifier extends AutoDisposeAsyncNotifier<List<QueueItem>> {
  Timer? _timer;
  bool _isFetching = false;
  bool _refreshPending = false;
  List<InstanceLoadFailure> _failures = const [];

  /// Returns the per-instance failures from the latest fetch, so the UI can
  /// distinguish partial data from a genuinely empty queue.
  List<InstanceLoadFailure> get failures => _failures;

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
    final requests = <Future<_InstanceQueueResult>>[];

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

    final results = await Future.wait(requests);
    final items = results.expand((result) => result.items).toList();
    _failures = results
        .map((result) => result.failure)
        .whereType<InstanceLoadFailure>()
        .toList();

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

  Future<_InstanceQueueResult> _fetchInstanceQueue(
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
          return _InstanceQueueResult(items: items);
        }
        page++;
      }
    } catch (error, stackTrace) {
      logger.error(
        '[QueueProvider] Failed to fetch queue for instance ${instance.id}',
        error,
        stackTrace,
      );
      return _InstanceQueueResult(
        items: items,
        failure: InstanceLoadFailure(
          instanceId: instance.id,
          instanceType: instance.type,
          instanceLabel: instance.label,
          message: 'Queue data could not be loaded.',
        ),
      );
    }
  }

  /// Manually refreshes the queue.
  ///
  /// Uses single-flight coalescing: if a fetch is already in flight, this
  /// call marks a refresh as pending instead of starting a parallel fetch,
  /// preventing a stale response from overwriting a newer one. The pending
  /// refresh always runs after the current fetch completes, so a refresh
  /// triggered right after a mutation (e.g. removing an item) is never lost.
  Future<void> refresh() async {
    if (_isFetching) {
      _refreshPending = true;
      return;
    }
    await _runFetch();
    while (_refreshPending) {
      _refreshPending = false;
      await _runFetch();
    }
  }

  Future<void> _runFetch() async {
    _isFetching = true;
    try {
      state = await AsyncValue.guard(() => _fetchQueue());
    } finally {
      _isFetching = false;
    }
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
