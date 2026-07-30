import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../core/services/logger_service.dart';
import 'data_providers.dart';
import 'instances_provider.dart';

/// Loads one page of logs from a selected Arr instance.
typedef LogPageLoader = Future<LogPage> Function({int page});

/// Configured Radarr and Sonarr instances that can provide server logs.
final arrLogInstancesProvider = Provider<List<Instance>>((ref) {
  final instances = ref.watch(
    instancesProvider.select((state) => state.instances),
  );
  return instances
      .where(
        (instance) =>
            instance.type == InstanceType.radarr ||
            instance.type == InstanceType.sonarr,
      )
      .toList(growable: false);
});

/// Explicit instance selected on the ARR Logs tab.
final selectedArrLogInstanceIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the explicit log source, falling back to the active Arr instances.
final selectedArrLogInstanceProvider = Provider<Instance?>((ref) {
  final instances = ref.watch(arrLogInstancesProvider);
  final selectedId = ref.watch(selectedArrLogInstanceIdProvider);

  if (selectedId != null) {
    for (final instance in instances) {
      if (instance.id == selectedId) return instance;
    }
  }

  final currentRadarr = ref.watch(currentRadarrInstanceProvider);
  if (currentRadarr != null &&
      instances.any((instance) => instance.id == currentRadarr.id)) {
    return currentRadarr;
  }

  final currentSonarr = ref.watch(currentSonarrInstanceProvider);
  if (currentSonarr != null &&
      instances.any((instance) => instance.id == currentSonarr.id)) {
    return currentSonarr;
  }

  return instances.isEmpty ? null : instances.first;
});

/// Log loader bound to the instance selected on the ARR Logs tab.
final arrLogLoaderProvider = Provider<LogPageLoader?>((ref) {
  final instance = ref.watch(selectedArrLogInstanceProvider);
  if (instance != null) {
    switch (instance.type) {
      case InstanceType.radarr:
        final repository = ref.watch(
          movieRepositoryForInstanceProvider(instance),
        );
        return ({int page = 1}) => repository.getLogs(page: page);
      case InstanceType.sonarr:
        final repository = ref.watch(
          seriesRepositoryForInstanceProvider(instance),
        );
        return ({int page = 1}) => repository.getLogs(page: page);
      case InstanceType.qbittorrent:
        return null;
    }
  }

  // Preserves compatibility for isolated provider tests and transitional states
  // while configured instances are still loading.
  final movieRepository = ref.watch(movieRepositoryProvider);
  if (movieRepository != null) {
    return ({int page = 1}) => movieRepository.getLogs(page: page);
  }
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  if (seriesRepository != null) {
    return ({int page = 1}) => seriesRepository.getLogs(page: page);
  }
  return null;
});

/// Provider for fetching and paginating logs from the selected Arr instance.
final logsProvider = AsyncNotifierProvider<LogsNotifier, LogPage>(
  LogsNotifier.new,
);

/// Manages the state and pagination of system logs.
class LogsNotifier extends AsyncNotifier<LogPage> {
  int _generation = 0;
  bool _isLoadingNextPage = false;

  @override
  Future<LogPage> build() async {
    _generation++;
    _isLoadingNextPage = false;
    final loader = ref.watch(arrLogLoaderProvider);
    return _fetchLogs(loader: loader);
  }

  Future<LogPage> _fetchLogs({int page = 1, LogPageLoader? loader}) async {
    final selectedLoader = loader ?? ref.read(arrLogLoaderProvider);
    if (selectedLoader == null) {
      return const LogPage(page: 1, pageSize: 50, totalRecords: 0, records: []);
    }
    return selectedLoader(page: page);
  }

  /// Fetches the next page of logs and appends it to the current list.
  ///
  /// Guards against instance switches and overlapping scroll-driven requests
  /// via a generation token plus a single-flight flag, so a delayed response
  /// from a previous source can never overwrite freshly loaded logs. When the
  /// next page fails to load, the previous records are preserved and the state
  /// transitions to [AsyncError] instead of remaining in [AsyncLoading].
  Future<void> fetchNextPage() async {
    if (_isLoadingNextPage) return;
    final currentStatus = state;
    if (currentStatus.value == null) return;

    final currentPage = currentStatus.value!.page;
    final pageSize = currentStatus.value!.pageSize;
    final totalRecords = currentStatus.value!.totalRecords;

    if (currentPage * pageSize >= totalRecords) return;

    final generation = ++_generation;
    _isLoadingNextPage = true;
    try {
      state = AsyncLoading<LogPage>().copyWithPrevious(currentStatus);
      final nextPage = await _fetchLogs(page: currentPage + 1);
      if (generation != _generation) return;
      state = AsyncData(
        LogPage(
          page: nextPage.page,
          pageSize: nextPage.pageSize,
          totalRecords: nextPage.totalRecords,
          records: [...currentStatus.value!.records, ...nextPage.records],
        ),
      );
    } catch (error, stackTrace) {
      if (generation != _generation) return;
      logger.warning(
        '[LogsNotifier] Failed to load next log page',
        error,
        stackTrace,
      );
      state = AsyncError<LogPage>(
        error,
        stackTrace,
      ).copyWithPrevious(currentStatus);
    } finally {
      if (generation == _generation) {
        _isLoadingNextPage = false;
      }
    }
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
          for (final failure in runFailures) ?failure,
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
