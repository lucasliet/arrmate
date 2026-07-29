import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import 'data_providers.dart';
import 'instances_provider.dart';

/// Loads independently recoverable system information for one instance.
final instanceStorageOverviewProvider = FutureProvider.autoDispose
    .family<InstanceStorageOverview, Instance>((ref, instance) async {
      final instanceRepository = ref.watch(instanceRepositoryProvider);
      final MovieRepository? movieRepository =
          instance.type == InstanceType.radarr
          ? ref.watch(movieRepositoryForInstanceProvider(instance))
          : null;
      final SeriesRepository? seriesRepository =
          instance.type == InstanceType.sonarr
          ? ref.watch(seriesRepositoryForInstanceProvider(instance))
          : null;

      final statusFuture = _loadSection(
        instance: instance,
        section: InstanceOverviewSection.status,
        message: 'Version information is unavailable.',
        operation: () => instanceRepository.getSystemStatus(instance),
      );
      final diskSpaceFuture = _loadSection(
        instance: instance,
        section: InstanceOverviewSection.diskSpace,
        message: 'Disk space information is unavailable.',
        operation: () => instanceRepository.getDiskSpace(instance),
      );
      final libraryFuture = _loadSection(
        instance: instance,
        section: InstanceOverviewSection.library,
        message: 'Library statistics are unavailable.',
        operation: () =>
            _loadLibraryStatistics(instance, movieRepository, seriesRepository),
      );

      final statusResult = await statusFuture;
      final diskSpaceResult = await diskSpaceFuture;
      final libraryResult = await libraryFuture;
      final failures = [
        statusResult.failure,
        libraryResult.failure,
        diskSpaceResult.failure,
      ].nonNulls.toList();

      return InstanceStorageOverview(
        instance: instance,
        status: statusResult.value,
        library: libraryResult.value,
        diskSpaces: diskSpaceResult.value,
        failures: failures,
      );
    });

/// Loads storage overviews for every configured Radarr and Sonarr instance.
final instanceStorageOverviewsProvider =
    FutureProvider.autoDispose<List<InstanceStorageOverview>>((ref) async {
      final instances = [
        ...ref.watch(instancesByTypeProvider(InstanceType.radarr)),
        ...ref.watch(instancesByTypeProvider(InstanceType.sonarr)),
      ];
      final overviewFutures = instances.map(
        (instance) =>
            ref.watch(instanceStorageOverviewProvider(instance).future),
      );
      return Future.wait(overviewFutures);
    });

Future<InstanceLibraryStatistics> _loadLibraryStatistics(
  Instance instance,
  MovieRepository? movieRepository,
  SeriesRepository? seriesRepository,
) async {
  return switch (instance.type) {
    InstanceType.radarr => InstanceLibraryStatistics.fromMovies(
      await movieRepository!.getMovies(),
    ),
    InstanceType.sonarr => InstanceLibraryStatistics.fromSeries(
      await seriesRepository!.getSeries(),
    ),
    InstanceType.qbittorrent => throw UnsupportedError(
      'Library statistics are not available for qBittorrent instances',
    ),
  };
}

Future<_SectionResult<T>> _loadSection<T>({
  required Instance instance,
  required InstanceOverviewSection section,
  required String message,
  required Future<T> Function() operation,
}) async {
  try {
    return _SectionResult(value: await operation());
  } catch (error, stackTrace) {
    logger.error(
      '[InstanceStorageProvider] Failed to load ${section.name} for instance ${instance.id}',
      error,
      stackTrace,
    );
    return _SectionResult(
      failure: InstanceOverviewFailure(section: section, message: message),
    );
  }
}

class _SectionResult<T> {
  final T? value;
  final InstanceOverviewFailure? failure;

  const _SectionResult({this.value, this.failure});
}
