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

/// Identifies the operation that failed while retrieving health information.
enum HealthConnectionOperation {
  /// Loading the server-reported health status failed.
  loadStatus,

  /// Starting a new server health check failed.
  runCheck,
}

/// Describes an operation that failed for a health source.
class HealthConnectionFailure {
  /// Creates a health connection failure.
  const HealthConnectionFailure({
    required this.service,
    required this.operation,
  });

  /// The service whose health operation failed.
  final String service;

  /// The operation that could not be completed.
  final HealthConnectionOperation operation;
}

/// Combines server-reported health checks with connection failures.
class HealthOverview {
  /// Creates a health overview.
  const HealthOverview({
    required this.configuredSourceCount,
    this.serverChecks = const [],
    this.connectionFailures = const [],
  });

  /// The number of configured services queried for health information.
  final int configuredSourceCount;

  /// Warnings and errors reported by the connected servers.
  final List<HealthCheck> serverChecks;

  /// Services whose health information could not be retrieved or refreshed.
  final List<HealthConnectionFailure> connectionFailures;
}

/// Provider for fetching system health checks from all active instances.
final healthProvider = AsyncNotifierProvider<HealthNotifier, HealthOverview>(
  () {
    return HealthNotifier();
  },
);

/// Loads and refreshes health information from active Arr instances.
class HealthNotifier extends AsyncNotifier<HealthOverview> {
  int _generation = 0;

  @override
  Future<HealthOverview> build() async {
    _generation++;
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);
    return _fetchHealth(movieRepo, seriesRepo);
  }

  Future<HealthOverview> _fetchHealth(
    MovieRepository? movieRepo,
    SeriesRepository? seriesRepo,
  ) async {
    final requests = <Future<_HealthSourceResult>>[];
    if (movieRepo != null) {
      requests.add(_fetchSource(service: 'Radarr', load: movieRepo.getHealth));
    }
    if (seriesRepo != null) {
      requests.add(_fetchSource(service: 'Sonarr', load: seriesRepo.getHealth));
    }

    final results = await Future.wait(requests);
    return HealthOverview(
      configuredSourceCount: requests.length,
      serverChecks: [for (final result in results) ...result.serverChecks],
      connectionFailures: [
        for (final result in results)
          if (result.failure != null) result.failure!,
      ],
    );
  }

  Future<_HealthSourceResult> _fetchSource({
    required String service,
    required Future<List<HealthCheck>> Function() load,
  }) async {
    try {
      return _HealthSourceResult(serverChecks: await load());
    } catch (error, stackTrace) {
      logger.error(
        '[HealthNotifier] Failed to load $service health status',
        error,
        stackTrace,
      );
      return _HealthSourceResult(
        failure: HealthConnectionFailure(
          service: service,
          operation: HealthConnectionOperation.loadStatus,
        ),
      );
    }
  }

  /// Starts new checks and then reloads the server-reported health status.
  Future<void> runHealthChecks() async {
    final generation = ++_generation;
    final movieRepo = ref.read(movieRepositoryProvider);
    final seriesRepo = ref.read(seriesRepositoryProvider);

    state = AsyncLoading<HealthOverview>().copyWithPrevious(state);
    final requests = <Future<HealthConnectionFailure?>>[];
    if (movieRepo != null) {
      requests.add(_runSource(service: 'Radarr', run: movieRepo.healthCheck));
    }
    if (seriesRepo != null) {
      requests.add(_runSource(service: 'Sonarr', run: seriesRepo.healthCheck));
    }

    final runFailures = await Future.wait(requests);
    if (generation != _generation) return;

    if (requests.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
    }
    if (generation != _generation) return;

    final overview = await _fetchHealth(movieRepo, seriesRepo);
    if (generation != _generation) return;

    state = AsyncData(
      HealthOverview(
        configuredSourceCount: overview.configuredSourceCount,
        serverChecks: overview.serverChecks,
        connectionFailures: [
          for (final failure in runFailures)
            if (failure != null) failure,
          ...overview.connectionFailures,
        ],
      ),
    );
  }

  Future<HealthConnectionFailure?> _runSource({
    required String service,
    required Future<void> Function() run,
  }) async {
    try {
      await run();
      return null;
    } catch (error, stackTrace) {
      logger.warning(
        '[HealthNotifier] Failed to start $service health check',
        error,
        stackTrace,
      );
      return HealthConnectionFailure(
        service: service,
        operation: HealthConnectionOperation.runCheck,
      );
    }
  }
}

class _HealthSourceResult {
  const _HealthSourceResult({this.serverChecks = const [], this.failure});

  final List<HealthCheck> serverChecks;
  final HealthConnectionFailure? failure;
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
