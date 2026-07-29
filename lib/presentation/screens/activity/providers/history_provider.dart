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
  final List<HistoryEvent> events;
  final InstanceLoadFailure? failure;

  const _InstanceHistoryResult({required this.events, this.failure});
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
    ref.watch(historyEventTypeFilterProvider);
    final radarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.radarr),
    );
    final sonarrInstances = ref.watch(
      instancesByTypeProvider(InstanceType.sonarr),
    );
    final instances = [...radarrInstances, ...sonarrInstances];

    _nextPageByInstance
      ..clear()
      ..addEntries(instances.map((instance) => MapEntry(instance.id, 1)));
    _hasMoreByInstance
      ..clear()
      ..addEntries(instances.map((instance) => MapEntry(instance.id, true)));
    _failures = const [];
    _generation++;
    return _fetchHistory(radarrInstances, sonarrInstances);
  }

  Future<List<HistoryEvent>> _fetchHistory(
    List<Instance> radarrInstances,
    List<Instance> sonarrInstances,
  ) async {
    final eventType = ref.read(historyEventTypeFilterProvider);
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
        ),
      );
    }

    final results = await Future.wait(requests);
    final events = results.expand((result) => result.events).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _failures = results
        .map((result) => result.failure)
        .whereType<InstanceLoadFailure>()
        .toList();
    return events;
  }

  Future<_InstanceHistoryResult> _fetchInstanceHistory(
    Instance instance,
    _HistoryPageLoader loadPage,
    HistoryEventType? eventType,
  ) async {
    if (!(_hasMoreByInstance[instance.id] ?? false)) {
      return const _InstanceHistoryResult(events: []);
    }

    final page = _nextPageByInstance[instance.id] ?? 1;
    try {
      final historyPage = await loadPage(
        page,
        ApiConstants.historyPageSize,
        eventType,
      );
      _nextPageByInstance[instance.id] = page + 1;
      _hasMoreByInstance[instance.id] = historyPage.hasMore;
      return _InstanceHistoryResult(
        events: historyPage.records
            .map((event) => event.copyWith(instanceId: instance.id))
            .toList(),
      );
    } catch (error, stackTrace) {
      logger.error(
        '[HistoryProvider] Failed to fetch history for instance ${instance.id}',
        error,
        stackTrace,
      );
      _hasMoreByInstance[instance.id] = false;
      return _InstanceHistoryResult(
        events: const [],
        failure: InstanceLoadFailure(
          instanceId: instance.id,
          instanceType: instance.type,
          instanceLabel: instance.label,
          message: 'History data could not be loaded.',
        ),
      );
    }
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

    try {
      final radarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.radarr),
      );
      final sonarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.sonarr),
      );
      final newEvents = await _fetchHistory(radarrInstances, sonarrInstances);
      if (generation != _generation) return;
      final events = [...currentEvents, ...newEvents]
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
    ref.invalidateSelf();
    await future;
  }
}
