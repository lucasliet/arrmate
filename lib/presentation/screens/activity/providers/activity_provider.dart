import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_load_failure_banner.dart';

typedef _QueuePageLoader = Future<QueueItems> Function(int page, int pageSize);

/// One instance and the call that reads a page of its queue.
class _InstanceQueueSource {
  final Instance instance;
  final _QueuePageLoader loadPage;

  const _InstanceQueueSource(this.instance, this.loadPage);
}

class _InstanceQueueResult {
  final List<QueueItem> items;
  final InstanceLoadFailure? failure;

  const _InstanceQueueResult({required this.items, this.failure});
}

class _QueueFetchResult {
  final List<QueueItem> items;
  final List<InstanceLoadFailure> failures;

  const _QueueFetchResult({required this.items, required this.failures});
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
  Completer<void>? _activeFetchCycle;
  List<InstanceLoadFailure> _failures = const [];
  List<_InstanceQueueSource> _sources = const [];
  int _generation = 0;

  /// Returns the per-instance failures from the latest fetch, so the UI can
  /// distinguish partial data from a genuinely empty queue.
  List<InstanceLoadFailure> get failures => _failures;

  @override
  Future<List<QueueItem>> build() async {
    final generation = ++_generation;
    _refreshPending = false;
    _failures = const [];
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isFetching) return;
      unawaited(refresh());
    });
    ref.onDispose(() => _timer?.cancel());
    _sources = _resolveSources();

    final result = await _fetchUntilCurrent(generation);
    if (generation == _generation) {
      _failures = result.failures;
    }
    return result.items;
  }

  Future<_QueueFetchResult> _fetchUntilCurrent(int generation) async {
    final cycle = Completer<void>();
    final previousCycle = _activeFetchCycle;
    _activeFetchCycle = cycle;
    if (previousCycle != null && !previousCycle.isCompleted) {
      previousCycle.complete();
    }
    _isFetching = true;
    try {
      while (true) {
        final result = await _fetchQueue();
        if (generation != _generation) {
          return result;
        }
        if (!_refreshPending) {
          return result;
        }
        _refreshPending = false;
      }
    } finally {
      if (generation == _generation) {
        _isFetching = false;
      }
      if (identical(_activeFetchCycle, cycle)) {
        _activeFetchCycle = null;
      }
      if (!cycle.isCompleted) {
        cycle.complete();
      }
    }
  }

  /// Resolves one loader per configured instance.
  ///
  /// The subscriptions live here and nowhere else: [build] is the only place a
  /// notifier may watch, so a change to the configured instances rebuilds the
  /// queue once, instead of every timer tick re-subscribing from inside a fetch
  /// and asking the framework to rebuild the notifier that is already running.
  List<_InstanceQueueSource> _resolveSources() {
    final sources = <_InstanceQueueSource>[];

    for (final instance in ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    )) {
      final repository = ref.watch(
        movieRepositoryForInstanceProvider(instance),
      );
      sources.add(
        _InstanceQueueSource(
          instance,
          (page, pageSize) =>
              repository.getQueue(page: page, pageSize: pageSize),
        ),
      );
    }

    for (final instance in ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    )) {
      final repository = ref.watch(
        seriesRepositoryForInstanceProvider(instance),
      );
      sources.add(
        _InstanceQueueSource(
          instance,
          (page, pageSize) =>
              repository.getQueue(page: page, pageSize: pageSize),
        ),
      );
    }

    return sources;
  }

  Future<_QueueFetchResult> _fetchQueue() async {
    final results = await Future.wait([
      for (final source in _sources)
        _fetchInstanceQueue(source.instance, source.loadPage),
    ]);
    final items = results.expand((result) => result.items).toList();
    final failures = results
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

    return _QueueFetchResult(items: items, failures: failures);
  }

  Future<_InstanceQueueResult> _fetchInstanceQueue(
    Instance instance,
    _QueuePageLoader loadPage,
  ) async {
    final itemsById = <int, QueueItem>{};
    var fetchedRecordCount = 0;
    var page = 1;

    try {
      while (true) {
        final queue = await loadPage(page, ApiConstants.queuePageSize);
        fetchedRecordCount += queue.records.length;
        for (final item in queue.records) {
          itemsById[item.id] = item.copyWith(
            instanceId: instance.id,
            instanceType: instance.type,
          );
        }
        if (fetchedRecordCount >= queue.totalRecords || queue.records.isEmpty) {
          return _InstanceQueueResult(items: itemsById.values.toList());
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
        items: itemsById.values.toList(),
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
      while (_isFetching) {
        final cycle = _activeFetchCycle;
        if (cycle == null) return;
        await cycle.future;
      }
      return;
    }
    final generation = ++_generation;
    try {
      final result = await _fetchUntilCurrent(generation);
      if (generation != _generation) return;
      _failures = result.failures;
      state = AsyncValue.data(result.items);
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      state = AsyncValue.error(error, stackTrace);
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
