import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/instances_provider.dart';

typedef _HistoryPageLoader =
    Future<HistoryPage> Function(
      int page,
      int pageSize,
      HistoryEventType? eventType,
    );

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
    return _fetchHistory(radarrInstances, sonarrInstances);
  }

  Future<List<HistoryEvent>> _fetchHistory(
    List<Instance> radarrInstances,
    List<Instance> sonarrInstances,
  ) async {
    final eventType = ref.read(historyEventTypeFilterProvider);
    final requests = <Future<List<HistoryEvent>>>[];

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

    final events = (await Future.wait(
      requests,
    )).expand((events) => events).toList();
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  Future<List<HistoryEvent>> _fetchInstanceHistory(
    Instance instance,
    _HistoryPageLoader loadPage,
    HistoryEventType? eventType,
  ) async {
    if (!(_hasMoreByInstance[instance.id] ?? false)) {
      return [];
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
      return historyPage.records
          .map((event) => event.copyWith(instanceId: instance.id))
          .toList();
    } catch (error, stackTrace) {
      logger.error(
        '[HistoryProvider] Failed to fetch history for instance ${instance.id}',
        error,
        stackTrace,
      );
      return [];
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

    try {
      final radarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.radarr),
      );
      final sonarrInstances = ref.read(
        instancesByTypeProvider(InstanceType.sonarr),
      );
      final newEvents = await _fetchHistory(radarrInstances, sonarrInstances);
      final events = [...currentEvents, ...newEvents]
        ..sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(events);
    } catch (e, stack) {
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
