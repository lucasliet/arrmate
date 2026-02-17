import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../core/services/logger_service.dart';
import 'data_providers.dart';

/// Provider for fetching and paginating system logs.
final logsProvider = AsyncNotifierProvider<LogsNotifier, LogPage>(() {
  return LogsNotifier();
});

/// Manages the state and pagination of system logs.
class LogsNotifier extends AsyncNotifier<LogPage> {
  @override
  Future<LogPage> build() async {
    return _fetchLogs();
  }

  Future<LogPage> _fetchLogs({int page = 1}) async {
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);

    // Simplified: Fetches logs from the first available instance (Radarr or Sonarr).
    if (movieRepo != null) {
      return movieRepo.getLogs(page: page);
    } else if (seriesRepo != null) {
      return seriesRepo.getLogs(page: page);
    }

    return const LogPage(page: 1, pageSize: 50, totalRecords: 0, records: []);
  }

  /// Fetches the next page of logs and appends it to the current list.
  Future<void> fetchNextPage() async {
    final currentStatus = state;
    if (currentStatus.value == null) return;

    final currentPage = currentStatus.value!.page;
    final totalRecords = currentStatus.value!.totalRecords;

    if (currentPage * 50 >= totalRecords) return;

    final previousState = state;
    state = AsyncLoading<LogPage>().copyWithPrevious(previousState);
    state = await AsyncValue.guard(() async {
      final nextPage = await _fetchLogs(page: currentPage + 1);
      return LogPage(
        page: nextPage.page,
        pageSize: nextPage.pageSize,
        totalRecords: nextPage.totalRecords,
        records: [...currentStatus.value!.records, ...nextPage.records],
      );
    });
  }
}

/// Provider for fetching system health checks from all active instances.
final healthProvider = AsyncNotifierProvider<HealthNotifier, List<HealthCheck>>(
  () {
    return HealthNotifier();
  },
);

class HealthNotifier extends AsyncNotifier<List<HealthCheck>> {
  @override
  Future<List<HealthCheck>> build() async {
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);
    return _fetchHealth(movieRepo, seriesRepo);
  }

  Future<List<HealthCheck>> _fetchHealth(
    MovieRepository? movieRepo,
    SeriesRepository? seriesRepo,
  ) async {
    List<HealthCheck> allChecks = [];

    if (movieRepo != null) {
      try {
        final checks = await movieRepo.getHealth();
        allChecks.addAll(checks);
      } catch (e, stack) {
        logger.error('health: movies fetch failed', e, stack);
      }
    }

    if (seriesRepo != null) {
      try {
        final checks = await seriesRepo.getHealth();
        allChecks.addAll(checks);
      } catch (e, stack) {
        logger.error('health: series fetch failed', e, stack);
      }
    }

    return allChecks;
  }

  Future<void> runHealthChecks() async {
    final movieRepo = ref.read(movieRepositoryProvider);
    final seriesRepo = ref.read(seriesRepositoryProvider);

    state = AsyncLoading<List<HealthCheck>>().copyWithPrevious(state);

    final futures = <Future<void>>[];
    if (movieRepo != null) {
      futures.add(
        movieRepo.healthCheck().catchError((e, stack) {
          logger.warning(
            '[HealthNotifier] healthCheck command failed for movie instance',
            e,
            stack,
          );
        }),
      );
    }
    if (seriesRepo != null) {
      futures.add(
        seriesRepo.healthCheck().catchError((e, stack) {
          logger.warning(
            '[HealthNotifier] healthCheck command failed for series instance',
            e,
            stack,
          );
        }),
      );
    }

    await Future.wait(futures);
    await Future.delayed(const Duration(seconds: 2));
    state = await AsyncValue.guard(() => _fetchHealth(movieRepo, seriesRepo));
  }
}

/// Provider for fetching Radarr quality profiles.
final movieQualityProfilesProvider = FutureProvider<List<QualityProfile>>((
  ref,
) async {
  final movieRepo = ref.watch(movieRepositoryProvider);
  if (movieRepo == null) return [];
  return movieRepo.getQualityProfiles();
});

/// Provider for fetching Sonarr quality profiles.
final seriesQualityProfilesProvider = FutureProvider<List<QualityProfile>>((
  ref,
) async {
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  if (seriesRepo == null) return [];
  return seriesRepo.getQualityProfiles();
});

/// Provider that streams internal application logs.
final appLogsProvider = StreamProvider<List<AppLogEntry>>((ref) async* {
  yield logger.logs;
  yield* logger.logStream;
});
