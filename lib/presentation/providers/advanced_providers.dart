import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../core/services/logger_service.dart';
import 'data_providers.dart';

// Logs Provider
final logsProvider = AsyncNotifierProvider<LogsNotifier, LogPage>(() {
  return LogsNotifier();
});

class LogsNotifier extends AsyncNotifier<LogPage> {
  @override
  Future<LogPage> build() async {
    return _fetchLogs();
  }

  Future<LogPage> _fetchLogs({int page = 1}) async {
    final movieRepo = ref.watch(movieRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);

    // Simplificação: Pegamos logs de uma instância ou combinamos.
    // Para simplificar a UI no início, pegaremos da primeira instância Radarr disponível.
    if (movieRepo != null) {
      return movieRepo.getLogs(page: page);
    } else if (seriesRepo != null) {
      return seriesRepo.getLogs(page: page);
    }

    return const LogPage(page: 1, pageSize: 50, totalRecords: 0, records: []);
  }

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

// Health Provider
final healthProvider = FutureProvider<List<HealthCheck>>((ref) async {
  final movieRepo = ref.watch(movieRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);

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
});

// Quality Profiles Provider (Fetching from instances)
final movieQualityProfilesProvider = FutureProvider<List<QualityProfile>>((
  ref,
) async {
  final movieRepo = ref.watch(movieRepositoryProvider);
  if (movieRepo == null) return [];
  return movieRepo.getQualityProfiles();
});

final seriesQualityProfilesProvider = FutureProvider<List<QualityProfile>>((
  ref,
) async {
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  if (seriesRepo == null) return [];
  return seriesRepo.getQualityProfiles();
});
