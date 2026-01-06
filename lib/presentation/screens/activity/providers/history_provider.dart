import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../../core/services/logger_service.dart';
import '../../../providers/data_providers.dart';

/// Provider for fetching and paginating history events.
final activityHistoryProvider =
    AsyncNotifierProvider.autoDispose<HistoryNotifier, List<HistoryEvent>>(
      HistoryNotifier.new,
    );

/// Provider to filter history events by their type (e.g., Grabbed, Failed).
final historyEventTypeFilterProvider = StateProvider<HistoryEventType?>(
  (ref) => null,
);

/// Notifier to manage history events and pagination.
class HistoryNotifier extends AutoDisposeAsyncNotifier<List<HistoryEvent>> {
  int _currentPage = 1;
  bool _hasMoreRadarr = true;
  bool _hasMoreSonarr = true;

  @override
  Future<List<HistoryEvent>> build() async {
    // Watch filter to trigger rebuild on change
    ref.watch(historyEventTypeFilterProvider);

    _currentPage = 1;
    _hasMoreRadarr = true;
    _hasMoreSonarr = true;
    return _fetchHistory(1);
  }

  Future<List<HistoryEvent>> _fetchHistory(int page) async {
    final movieRepo = ref.read(movieRepositoryProvider);
    final seriesRepo = ref.read(seriesRepositoryProvider);
    final eventType = ref.read(historyEventTypeFilterProvider);

    final events = <HistoryEvent>[];

    if (movieRepo != null && _hasMoreRadarr) {
      try {
        final historyPage = await movieRepo.getHistory(
          page: page,
          pageSize: 25,
          eventType: eventType,
        );
        events.addAll(historyPage.records);
        _hasMoreRadarr = historyPage.hasMore;
      } catch (e) {
        // Ignore errors from individual instances
      }
    }

    if (seriesRepo != null && _hasMoreSonarr) {
      try {
        final historyPage = await seriesRepo.getHistory(
          page: page,
          pageSize: 25,
          eventType: eventType,
        );
        events.addAll(historyPage.records);
        _hasMoreSonarr = historyPage.hasMore;
      } catch (e) {
        // Ignore errors from individual instances
      }
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  /// Checks if there are more pages available to load.
  bool get hasMore => _hasMoreRadarr || _hasMoreSonarr;

  /// Loads the next page of history events and appends them to the list.
  Future<void> loadMore() async {
    if (!hasMore) return;
    if (state.isLoading) return;

    final previousState = state;
    state = const AsyncLoading<List<HistoryEvent>>().copyWithPrevious(
      previousState,
    );

    try {
      _currentPage++;
      final currentEvents = state.valueOrNull ?? [];
      final newEvents = await _fetchHistory(_currentPage);
      state = AsyncValue.data([...currentEvents, ...newEvents]);
    } catch (e, stack) {
      _currentPage--;
      state = AsyncValue.error(e, stack);
      logger.error('History loadMore failed', e, stack);
    }
  }

  /// Refreshes the history list, resetting pagination.
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMoreRadarr = true;
    _hasMoreSonarr = true;
    ref.invalidateSelf();
    await future;
  }
}
