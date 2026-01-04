import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/models.dart';
import '../../../providers/data_providers.dart';

// Queue Provider
final queueProvider = AsyncNotifierProvider.autoDispose<QueueNotifier, List<QueueItem>>(
  QueueNotifier.new,
);

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
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);

    final items = <QueueItem>[];

    if (movieRepo != null) {
      try {
        final queue = await movieRepo.getQueue();
        items.addAll(queue.records);
      } catch (e) {/*ignore*/}
    }

    if (seriesRepo != null) {
      try {
        final queue = await seriesRepo.getQueue();
        items.addAll(queue.records);
      } catch (e) {/*ignore*/}
    }

    // Sort by timeleft? or added?
    // Usually users want to see what's finishing soonest first, or what's stalling.
    // Let's sort by timeleft (estimatedCompletionTime). 
    // Note: timeleft is a String in some models or calculated?
    // QueueItem has `timeleft` string usually, but `estimatedCompletionTime` DateTime.
    
    items.sort((a, b) {
      if (a.estimatedCompletionTime == null && b.estimatedCompletionTime == null) return 0;
      if (a.estimatedCompletionTime == null) return 1;
      if (b.estimatedCompletionTime == null) return -1;
      return a.estimatedCompletionTime!.compareTo(b.estimatedCompletionTime!);
    });

    return items;
  }

  Future<void> refresh() async {
    // Silent refresh if already loaded?
    // Using ref.invalidateSelf() triggers loading state. W
    // We might want to keep previous state while updating for polling.
    // For now, standard invalidate.
    if (state.isLoading) return;
    
    // We can manually update state to new value to avoid loading flicker
    state = await AsyncValue.guard(() => _fetchQueue());
  }

  Future<void> removeQueueItem(
    int id, {
    bool removeFromClient = true,
    bool blocklist = false,
    bool skipRedownload = false,
  }) async {
    final movieRepo = ref.read(movieRepositoryProvider);
    final seriesRepo = ref.read(seriesRepositoryProvider);

    try {
      if (movieRepo != null) {
        await movieRepo.deleteQueueItem(
          id,
          removeFromClient: removeFromClient,
          blocklist: blocklist,
          skipRedownload: skipRedownload,
        );
      }
    } catch (e) {
      // Item might be from Sonarr, try that
    }

    try {
      if (seriesRepo != null) {
        await seriesRepo.deleteQueueItem(
          id,
          removeFromClient: removeFromClient,
          blocklist: blocklist,
          skipRedownload: skipRedownload,
        );
      }
    } catch (e) {
      // Item might be from Radarr, already tried
    }

    await refresh();
  }
}

// History Provider (Placeholder for now, usually paginated)
final historyProvider = FutureProvider.autoDispose<List<HistoryItem>>((ref) async {
   // History API is usually /history
   // Not yet fully implemented in repositories?
   return [];
});

class HistoryItem {
  // Skeleton
}
