import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error.dart';
import '../../core/services/logger_service.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import 'data_providers.dart';
import 'instances_provider.dart';
import 'jellyfin_session_state_provider.dart';

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

/// Checks the stored session of every Jellyfin instance against its server.
///
/// A server that accepts the session clears any expired flag, while a server
/// that rejects it with "session has expired" flags the instance. Any other
/// failure, such as an offline or slow server, is logged and leaves the flag
/// untouched, so an unreachable server never marks a session as expired.
/// Instances without a user session (API key) are skipped.
final jellyfinSessionStatusProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final instances = ref
      .watch(instancesByTypeProvider(InstanceType.jellyfin))
      .where((instance) => instance.userSession != null)
      .toList();
  if (instances.isEmpty) return;

  final instanceRepository = ref.watch(instanceRepositoryProvider);
  final expiredNotifier = ref.read(jellyfinSessionExpiredProvider.notifier);
  await Future.wait(
    instances.map((instance) async {
      try {
        await Future.sync(() => instanceRepository.getSystemStatus(instance));
        expiredNotifier.clear(instance.id);
      } on UnauthorizedError catch (error, stackTrace) {
        if (error.message.contains('session has expired')) {
          expiredNotifier.markExpired(instance.id);
        } else {
          logger.warning(
            '[JellyfinSessionStatus] Session check failed for instance '
            '${instance.id}',
            error,
            stackTrace,
          );
        }
      } catch (error, stackTrace) {
        logger.warning(
          '[JellyfinSessionStatus] Session check failed for instance '
          '${instance.id}',
          error,
          stackTrace,
        );
      }
    }),
  );
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
    // Design decision: Throw UnsupportedError instead of returning empty data
    // so the section loader reports the section as unavailable, mirroring
    // qBittorrent. Jellyfin overviews are never requested upstream, but the
    // switch must stay exhaustive over the instance types.
    InstanceType.qbittorrent || InstanceType.jellyfin => throw UnsupportedError(
      'Library statistics are not available for ${instance.type.label} instances',
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
    final failureMessage = error is UnauthorizedError ? error.message : message;
    return _SectionResult(
      failure: InstanceOverviewFailure(
        section: section,
        message: failureMessage,
      ),
    );
  }
}

class _SectionResult<T> {
  final T? value;
  final InstanceOverviewFailure? failure;

  const _SectionResult({this.value, this.failure});
}
