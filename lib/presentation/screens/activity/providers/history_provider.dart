import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/models.dart';
import '../../../providers/data_providers.dart';

final activityHistoryProvider =
    AsyncNotifierProvider.autoDispose<HistoryNotifier, List<HistoryEvent>>(
      HistoryNotifier.new,
    );

final historyEventTypeFilterProvider = StateProvider<HistoryEventType?>(
  (ref) => null,
);

class HistoryNotifier extends AutoDisposeAsyncNotifier<List<HistoryEvent>> {
  int _currentPage = 1;
  bool _hasMoreRadarr = true;
  bool _hasMoreSonarr = true;

  @override
  Future<List<HistoryEvent>> build() async {
    _currentPage = 1;
    _hasMoreRadarr = true;
    _hasMoreSonarr = true;
    return _fetchHistory(1);
  }

  Future<List<HistoryEvent>> _fetchHistory(int page) async {
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);
    final eventType = ref.watch(historyEventTypeFilterProvider);

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

  bool get hasMore => _hasMoreRadarr || _hasMoreSonarr;

  Future<void> loadMore() async {
    if (!hasMore) return;
    if (state.isLoading) return;

    _currentPage++;
    final currentEvents = state.valueOrNull ?? [];
    final newEvents = await _fetchHistory(_currentPage);

    state = AsyncValue.data([...currentEvents, ...newEvents]);
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMoreRadarr = true;
    _hasMoreSonarr = true;
    ref.invalidateSelf();
    await future;
  }
}
