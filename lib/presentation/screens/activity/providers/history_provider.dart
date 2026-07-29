import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';
import '../../../widgets/instance_load_failure_banner.dart';

typedef _HistoryPageLoader =
    Future<HistoryPage> Function(
      int page,
      int pageSize,
      HistoryEventType? eventType,
    );

class _InstanceHistoryResult {
  final String instanceId;
  final List<HistoryEvent> events;
  final InstanceLoadFailure? failure;
  final int nextPage;
  final bool hasMore;
  final bool attempted;

  const _InstanceHistoryResult({
    required this.instanceId,
    required this.events,
    required this.nextPage,
    required this.hasMore,
    required this.attempted,
    this.failure,
  });
}

class _HistoryFetchResult {
  final List<_InstanceHistoryResult> instances;

  const _HistoryFetchResult(this.instances);

  List<HistoryEvent> get events =>
      instances.expand((result) => result.events).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<InstanceLoadFailure> get failures => instances
      .map((result) => result.failure)
      .whereType<InstanceLoadFailure>()
      .toList();
}

/// Provider for fetching and paginating history events.
final activityHistoryProvider =
    AsyncNotifierProvider.autoDispose<HistoryNotifier, List<HistoryEvent>>(
      HistoryNotifier.new,
    );

/// Provider to filter history events by their type (e.g., Grabbed, Failed).
final historyEventTypeFilterProvider = StateProvider<HistoryEventType?>(
  (ref) => null,
);

/// Provider to filter history events by their originating instance.
final historyInstanceFilterProvider = StateProvider<String?>((ref) => null);

/// Exposes per-instance history failures so the UI can surface partial data
/// alongside a retry banner instead of treating it as an empty history.
final historyFailuresProvider = Provider.autoDispose<List<InstanceLoadFailure>>(
  (ref) {
    ref.watch(activityHistoryProvider);
    return ref.watch(activityHistoryProvider.notifier).failures;
  },
);

/// Provider exposing history events after applying the instance filter.
final filteredActivityHistoryProvider =
    Provider<AsyncValue<List<HistoryEvent>>>((ref) {
      final historyAsync = ref.watch(activityHistoryProvider);
      final instanceFilter = ref.watch(historyInstanceFilterProvider);
      if (instanceFilter == null) {
        return historyAsync;
      }
      return historyAsync.whenData(
        (events) => events
            .where((event) => event.instanceId == instanceFilter)
            .toList(),
      );
    });

/// Notifier to manage history events and pagination.
class HistoryNotifier extends AutoDisposeAsyncNotifier<List<HistoryEvent>> {
  final Map<String, int> _nextPageByInstance = {};
  final Map<String, bool> _hasMoreByInstance = {};
  List<InstanceLoadFailure> _failures = const [];

  /// Monotonic generation token incremented whenever [build] or [refresh]
  /// starts, so late completions from an abandoned fetch cannot overwrite a
  /// newer state or its pagination cursors.
  int _generation = 0;

  /// Returns the per-instance failures from the latest fetch, so the UI can
  /// distinguish partial data from a genuinely empty history.
  List<InstanceLoadFailure> get failures => _failures;

  @override
  Future<List<HistoryEvent>> build() async {
    final eventType = ref.watch(historyEventTypeFilterProvider);
    final radarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    );
    final sonarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    );
    final instances = [...radarrInstances, ...sonarrInstances];
    final nextPages = {for (final instance in instances) instance.id: 1};
    final hasMoreByInstance = {
      for (final instance in instances) instance.id: true,
    };
    final generation = ++_generation;

    final result = await _fetchHistory(
      radarrInstances,
      sonarrInstances,
      eventType: eventType,
      nextPages: nextPages,
      hasMoreByInstance: hasMoreByInstance,
    );
    if (generation != _generation) {
      return state.valueOrNull ?? const [];
    }
    _nextPageByInstance
      ..clear()
      ..addAll(nextPages);
    _hasMoreByInstance
      ..clear()
      ..addAll(hasMoreByInstance);
    _applyPagination(result);
    _failures = result.failures;
    return result.events;
  }

  Future<_HistoryFetchResult> _fetchHistory(
    List<Instance> radarrInstances,
    List<Instance> sonarrInstances, {
    required HistoryEventType? eventType,
    required Map<String, int> nextPages,
    required Map<String, bool> hasMoreByInstance,
  }) async {
    final requests = <Future<_InstanceHistoryResult>>[];

    for (final instance in radarrInstances) {
      final repository = ref.read(movieRepositoryForInstanceProvider(instance));
      requests.add(
        _fetchInstanceHistory(
          instance,
          (page, pageSize, eventType) => repository.getHistory(
            page: page,
            pageSize: pageSize,
            eventType: eventType,
          ),
          eventType,
          page: nextPages[instance.id] ?? 1,
          hasMore: hasMoreByInstance[instance.id] ?? false,
        ),
      );
    }

    for (final instance in sonarrInstances) {
      final repository = ref.read(
        seriesRepositoryForInstanceProvider(instance),
      );
      requests.add(
        _fetchInstanceHistory(
          instance,
          (page, pageSize, eventType) => repository.getHistory(
            page: page,
            pageSize: pageSize,
            eventType: eventType,
          ),
          eventType,
          page: nextPages[instance.id] ?? 1,
          hasMore: hasMoreByInstance[instance.id] ?? false,
        ),
      );
    }

    return _HistoryFetchResult(await Future.wait(requests));
  }

  Future<_InstanceHistoryResult> _fetchInstanceHistory(
    Instance instance,
    _HistoryPageLoader loadPage,
    HistoryEventType? eventType, {
    required int page,
    required bool hasMore,
  }) async {
    if (!hasMore) {
      return _InstanceHistoryResult(
        instanceId: instance.id,
        events: const [],
        nextPage: page,
        hasMore: false,
        attempted: false,
      );
    }

    try {
      final historyPage = await loadPage(
        page,
        ApiConstants.historyPageSize,
        eventType,
      );
      return _InstanceHistoryResult(
        instanceId: instance.id,
        events: historyPage.records
            .map((event) => event.copyWith(instanceId: instance.id))
            .toList(),
        nextPage: page + 1,
        hasMore: historyPage.hasMore,
        attempted: true,
      );
    } catch (error, stackTrace) {
      logger.error(
        '[HistoryProvider] Failed to fetch history for instance ${instance.id}',
        error,
        stackTrace,
      );
      return _InstanceHistoryResult(
        instanceId: instance.id,
        events: const [],
        nextPage: page,
        hasMore: false,
        attempted: true,
        failure: InstanceLoadFailure(
          instanceId: instance.id,
          instanceType: instance.type,
          instanceLabel: instance.label,
          message: 'History data could not be loaded.',
        ),
      );
    }
  }

  void _applyPagination(_HistoryFetchResult result) {
    for (final instance in result.instances) {
      if (!instance.attempted) {
        continue;
      }
      _nextPageByInstance[instance.instanceId] = instance.nextPage;
      _hasMoreByInstance[instance.instanceId] = instance.hasMore;
    }
  }

  List<InstanceLoadFailure> _mergeFailures(
    List<InstanceLoadFailure> existing,
    List<InstanceLoadFailure> added,
  ) {
    final failures = {
      for (final failure in existing)
        '${failure.instanceType.name}:${failure.instanceId}': failure,
      for (final failure in added)
        '${failure.instanceType.name}:${failure.instanceId}': failure,
    };
    return failures.values.toList();
  }

  /// Checks if there are more pages available to load.
  bool get hasMore => _hasMoreByInstance.values.any((hasMore) => hasMore);

  /// Loads the next page of history events and appends them to the list.
  Future<void> loadMore() async {
    if (!hasMore) return;
    if (state.isLoading) return;

    final currentEvents = state.valueOrNull ?? [];
    final previousState = state;
    state = const AsyncLoading<List<HistoryEvent>>().copyWithPrevious(
      previousState,
    );
    final generation = _generation;
    final eventType = ref.read(historyEventTypeFilterProvider);
    final nextPages = Map<String, int>.of(_nextPageByInstance);
    final hasMoreByInstance = Map<String, bool>.of(_hasMoreByInstance);

    try {
      final radarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.radarr),
      );
      final sonarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.sonarr),
      );
      final result = await _fetchHistory(
        radarrInstances,
        sonarrInstances,
        eventType: eventType,
        nextPages: nextPages,
        hasMoreByInstance: hasMoreByInstance,
      );
      if (generation != _generation) return;
      _applyPagination(result);
      _failures = _mergeFailures(_failures, result.failures);
      final eventsByIdentity = <String, HistoryEvent>{};
      for (final event in [...currentEvents, ...result.events]) {
        eventsByIdentity['${event.instanceId}:${event.id}'] = event;
      }
      final events = eventsByIdentity.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(events);
    } catch (e, stack) {
      if (generation != _generation) return;
      state = AsyncValue.error(e, stack);
      logger.error('[HistoryProvider] Load more failed', e, stack);
    }
  }

  /// Refreshes the history list, resetting pagination.
  Future<void> refresh() async {
    _generation++;
    ref.invalidateSelf();
    await future;
  }
}
